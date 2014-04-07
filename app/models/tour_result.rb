# coding: utf-8

require "bicycle_tour_manager"
require "stringio"
require "fileutils"

class TourResult < ActiveRecord::Base
	has_many :public_result_routes, -> { order("position ASC") }
	has_many :private_result_routes, -> { order("position ASC") }
	has_many :tour_images, -> { order("shot_on ASC") }

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
			(TourResult.where(["start_time >= ?", tour.start_time]).count - 1) / 10 + 1
		else
			1
		end
	end

	def self.load(stream, time_zone)
		tour = BTM::GpxStream.read_from_stream(stream)

		tour_result = TourResult.new
		tour_result.name = tour.name
		tour_result.start_time = tour.routes[0].path_list[0].steps[0].time
		tour_result.finish_time = tour.routes[-1].path_list[-1].steps[-1].time

		# 非公開
		tour.routes.each do |r|
			r.path_list.each do |p|
				pri_route = tour_result.private_result_routes.build

				logger.debug("check peak")
				p.check_peak
				p.check_distance_from_start

				logger.debug("check steps")
				line_points = []
				prev_line = p.steps.first
				prev_pt = p.steps.first

				p.steps.each do |s|
					add_line = false
					add_point = false

					if s.min_max != nil
						add_line = true
						add_point = true
					else
						add_line = (prev_line.distance_on_path(s) > 0.05)
						add_point = (prev_pt.distance_on_path(s) > 0.15)
					end

					if add_line
						line_points << s.point_geos
						prev_line = s
					end

					if add_point
						pt = ResultPoint.new
						pt.point = s.point_geos
						pt.elevation = s.ele
						pt.time = s.time.getlocal

						pri_route.result_points << pt

						prev_pt = s
					end
				end

				line = BTM.factory.line_string(line_points)

				pri_route.start_time = p.steps[0].time.getlocal
				pri_route.finish_time = p.steps[-1].time.getlocal
				pri_route.path = line
			end
		end

		# 公開
		ExclusionArea.all.each do |area|
			tour.delete_by_distance(area.point, area.distance)
		end

		tour.routes.each do |r|
			r.path_list.each do |p|
				pub_route = tour_result.public_result_routes.build

				logger.debug("check peak")
				p.check_peak
				p.check_distance_from_start

				logger.debug("check steps")
				line_points = []
				prev_line = p.steps.first
				prev_pt = p.steps.first

				p.steps.each do |s|
					add_line = false
					add_point = false

					if s.min_max != nil
						add_line = true
						add_point = true
					else
						add_line = (prev_line.distance_on_path(s) > 0.05)
						add_point = (prev_pt.distance_on_path(s) > 0.15)
					end

					if add_line
						line_points << s.point_geos
						prev_line = s
					end

					if add_point
						pt = ResultPoint.new
						pt.point = s.point_geos
						pt.elevation = s.ele
						pt.time = s.time.getlocal

						pub_route.result_points << pt

						prev_pt = s
					end
				end

				line = BTM.factory.line_string(line_points)

				pub_route.start_time = p.steps[0].time.getlocal
				pub_route.finish_time = p.steps[-1].time.getlocal
				pub_route.path = line
			end
		end

		tour_result.time_zone = time_zone

		tour_result
	end

	def self.load_and_save(user, gpx_file, time_zone)
		if user.can? :edit, TourResult
			tour_result = self.load(gpx_file, time_zone)
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

			case kind
			when :route
				r.path.points.each do |p|
					pt = BTM::Point.new(p.y, p.x)
					tour.routes.last.path_list.last.steps << pt
				end

			when :graph
				r.result_points.each do |p|
					pt = BTM::Point.new(p.point.y, p.point.x, p.elevation)
					pt.time = p.time
					tour.routes.last.path_list.last.steps << pt
				end
			end
		end

		tour.set_start_end
		tour
	end

	def to_gpx(is_public_data, kind)
		tour = self.to_tour(is_public_data, kind)
		io = StringIO.new("", "w")
		BTM::GpxStream.write_routes_to_stream(io, tour)
		io.string
	end

	def plot_altitude_graph(is_public_data)
		tour = self.to_tour(is_public_data, :graph)

		plotter = BTM::AltitudePloter.new("gnuplot", File.join(Rails.root, "tmp"))
		plotter.elevation_max = 1100
		plotter.elevation_min = -100
		plotter.distance_max = (tour.total_distance + 10.0).to_i
		plotter.font = File.join(Rails.root, "vendor/font/mikachan-p.ttf")

		FileUtils.mkdir_p(File.dirname(altitude_graph_path))
		plotter.plot(tour, altitude_graph_path)
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
			ret = TourResult.find(id)
			ret.published = !ret.published
			ret.save!
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

	def time_zone
		'Tokyo'
	end

	def start_time_on_local
		start_time.in_time_zone(time_zone)
	end

	def finish_time_on_local
		finish_time.in_time_zone(time_zone)
	end
end
