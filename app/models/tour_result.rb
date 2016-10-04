# coding: utf-8

require "bicycle_tour_manager"
require "stringio"
require "fileutils"

class TourResult < ActiveRecord::Base
	has_many :public_result_routes, -> { order("position ASC") }, dependent: :destroy
	has_many :private_result_routes, -> { order("position ASC") }, dependent: :destroy
	has_many :tour_images, -> { order("shot_on ASC") }, dependent: :destroy
	belongs_to :tour_plan

	before_save -> { update_elevation }
	after_save -> { plot_altitude_graph(true) }

	def self.list_all(user, page)
		if user.can? :edit, TourResult
			TourResult.paginate(page: page, per_page: 10).order("start_time DESC")
		else
			TourResult.paginate(page: page, per_page: 10).where("published = true").order("start_time DESC")
		end
	end

	def self.page_for(user, id)
		tour = find_with_auth(user, id)
		if tour
			count = 0
			if user.can? :edit, TourResult
				count = TourResult.where(["start_time >= ?", tour.start_time]).count
			else
				count = TourResult.where(["published = true AND start_time >= ?", tour.start_time]).count
			end
			(count - 1) / 10 + 1
		else
			1
		end
	end

	def self.load(stream, attr)
		tour = BTM::GpxStream.read_from_stream(stream)

		tour_result = TourResult.new
		tour_result.name = tour.name
		tour_result.start_time = tour.routes[0].path_list[0].steps[0].time
		tour_result.finish_time = tour.routes[-1].path_list[-1].steps[-1].time

		# 非公開
		offset = 0.0
		tour.routes.each do |r|
			r.path_list.each do |p|
				pri_route = tour_result.private_result_routes.build
				pri_route.time = []
				pri_route.speed = []

				logger.debug("check peak")
				p.check_distance_from_start(offset)
				offset = p.steps.last.distance_from_start

				BTM::Path.check_peak(p.steps)

				logger.debug("check steps")
				line_points = []
				prev_pt = p.steps.first

				p.steps.each do |s|
					add_point = false

					if s.min_max != nil
						add_point = true
					else
						add_point = (prev_pt.distance_on_path(s) > 0.05)
					end

					if add_point
						line_points << s.point_geos
						pri_route.time << s.time.getlocal
						pri_route.speed << 0.0
						prev_pt = s
					end
				end

				line = BTM.factory.line_string(line_points)

				pri_route.start_time = p.steps[0].time.getlocal
				pri_route.finish_time = p.steps[-1].time.getlocal
				pri_route.path = line
			end
		end

		tour_result.elevation = tour.total_elevation

		# 公開
		ExclusionArea.all.each do |area|
			pt = BTM::Point.new(area.point.y, area.point.x)
			tour.delete_by_distance(pt, area.distance)
		end

		offset = 0.0
		tour.routes.each do |r|
			r.path_list.each do |p|
				pub_route = tour_result.public_result_routes.build
				pub_route.time = []
				pub_route.speed = []

				logger.debug("check peak")
				p.check_distance_from_start(offset)
				offset = p.steps.last.distance_from_start

				BTM::Path.check_peak(p.steps)

				logger.debug("check steps")
				line_points = []
				prev_pt = p.steps.first

				p.steps.each do |s|
					add_point = false

					if s.min_max != nil
						add_point = true
					else
						add_point = (prev_pt.distance_on_path(s) > 0.05)
					end

					if add_point
						line_points << s.point_geos
						pub_route.time << s.time.getlocal
						pub_route.speed << 0.0
						prev_pt = s
					end
				end

				line = BTM.factory.line_string(line_points)

				pub_route.start_time = p.steps[0].time.getlocal
				pub_route.finish_time = p.steps[-1].time.getlocal
				pub_route.path = line
			end
		end

		tour_result.update_attributes(attr)

		tour_result
	end

	def self.load_and_save(user, gpx_file, attr)
		if user.can? :edit, TourResult
			tour_result = self.load(gpx_file, attr)
			tour_result.need_update_graph = true
			tour_result.published = false
			tour_result.save!
			tour_result
		else
			nil
		end
	end

	def self.add_images(user, id, images)
		if user.can? :edit, TourResult
			tour_result = TourResult.find(id)

			images.each do |i|
				tour_result.tour_images.build(image_data: i)
			end

			tour_result.save!
		end

		nil
	end

	def self.find_with_auth(user, id)
		ret = TourResult.find(id)
		if ! user.can?(:edit, TourResult) && !ret.published
			ret = nil
		else
			ret.tour_images.each {|i| i.tour_result = ret }
		end
		ret
	end

	def to_tour(is_public_data, kind)
		tour = BTM::Tour.new
		tour.start_date = self.start_time
		tour.name = self.name

		list = []
		if is_public_data
			list = self.public_result_routes
		else
			list = self.private_result_routes
		end

		list.each do |r|
			tour.routes << BTM::Route.new
			tour.routes.last.path_list << BTM::Path.new
			tour.routes.last.index = tour.routes.count

			case kind
			when :route
				r.path.points.each do |p|
					pt = BTM::Point.new(p.y, p.x, p.z)
					tour.routes.last.path_list.last.steps << pt
				end

			when :graph
				r.path.points.each.with_index do |p, i|
					pt = BTM::Point.new(p.y, p.x, p.z)
					pt.time = r.time[i]
					tour.routes.last.path_list.last.steps << pt
				end
			end

			tour.routes.last.path_list.last.way_points << tour.routes.last.path_list.last.steps[0]
		end

		tour.routes.last.path_list.last.way_points << tour.routes.last.path_list.last.steps.last

		tour.set_start_end
		tour
	end

	def to_gpx(is_public_data, kind)
		tour = self.to_tour(is_public_data, kind)
		io = StringIO.new("", "w")
		BTM::GpxStream.write_routes_to_stream(io, tour)
		io.string
	end

	def update_elevation
		self.elevation = to_tour(false, :graph).total_elevation
	end

	def plot_altitude_graph(is_public_data)
		if need_update_graph
			tour = self.to_tour(is_public_data, :graph)

			min, max = *tour.elevation_minmax
			min ||= 0
			max ||= 1000

			plotter = BTM::AltitudePloter.new("gnuplot", File.join(Rails.root, "tmp"))
			plotter.elevation_min = (min / 100) * 100 - 100
			plotter.elevation_max = [plotter.elevation_min + 1000, ((max - 1) / 100 + 1) * 100].max + 100
			plotter.distance_max = (tour.total_distance + 10.0).to_i
			plotter.font = File.join(Rails.root, "vendor/font/mikachan-p.ttf")

			FileUtils.mkdir_p(File.dirname(altitude_graph_path))
			plotter.plot(tour, altitude_graph_path)

			need_update_graph = false
		end
	end

	def altitude_graph_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, altitude_graph_url)
	end

	def altitude_graph_url
		"/generated/tour_result/altitude_graph/#{id}.png"
	end

	def self.destroy_with_auth(user, id)
		if user.can? :delete, TourResult
			destroy(id)
		end
	end

	def self.toggle_visible(user, id)
		if user.can? :edit, TourResult
			TourResult.where(["id = ?", id]).update_all("published = CASE WHEN published = TRUE THEN FALSE ELSE TRUE END")
		end
	end

	def distance(is_public_data)
		table_name = is_public_data ? "public_result_routes" : "private_result_routes"
		ret = TourResult.find_by_sql([<<-EOS, id])[0].length
SELECT ST_Length(t.path, false) as length FROM
	(SELECT ST_Collect(path) AS path FROM #{table_name} WHERE tour_result_id = ?) as t
		EOS
		ret.to_i / 1000
	end

	def start_time_on_local
		start_time.in_time_zone(time_zone)
	end

	def finish_time_on_local
		finish_time.in_time_zone(time_zone)
	end

	attr_accessor :need_update_graph
end
