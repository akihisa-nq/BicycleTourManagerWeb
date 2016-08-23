# coding: utf-8

require "bicycle_tour_manager"

class TourPlanGenerator
	def initialize(id, make_pdf)
		@plan = TourPlan.find(id)
		@parser = BTM::GoogleMapUriParser.new(TourPlanCache)
		@tour = BTM::Tour.new
		@tour.start_date = @plan.start_time_local

		@plotter = BTM::AltitudePloter.new("gnuplot", File.join(Rails.root, "tmp"))
		@plotter.font = File.join(Rails.root, "vendor/font/mikachan-p.ttf")
		@plotter.distance_max = 160.0
		@plotter.label = false

		@option = {
			enable_hide: false,
			scale: (@plan.planning_sheet_scale || 0.8)
		}
		@renderer = BTM::PlanHtmlRenderer.new(
			make_pdf ? @plotter : nil,
			@option
			)
	end

	def create_nodes
		points_old = []
		@plan.tour_plan_routes.each do |route|
			points_old += route.tour_plan_points
			route.tour_plan_points.destroy_all
		end

		offset = 0.0
		@plan.tour_plan_routes.each do |route|
			route.tour_plan_paths.each do |path|
				next if path.google_map_url.nil? || path.google_map_url.empty?

				# ルートの探索
				btmw_route = @parser.parse_uri(path.google_map_url)
				begin
					btmw_route.search_route(TourPlanCache, TourPlanCache)
				rescue => e
					TourPlan::logger.fatal(e.inspect)
					raise e
				end

				# 距離の算出
				btmw_route.path_list.each do |btmw_path|
					btmw_path.set_start_end
				end

				btmw_route.check_distance_from_start(offset)
				offset = btmw_route.path_list.last.end.distance_from_start

				# ノードの追加
				btmw_route.path_list.each.with_index do |btmw_path, i|
					next if route.tour_plan_points.count > 0 && i == 0

					btmw_node = btmw_path.start

					# 分岐点の追加
					node = route.tour_plan_points.create(
						point: btmw_node.point_geos,
						direction: TourPlanPoint.direction_with_node_info(btmw_node.info)
						)

					# ピークを通過点として追加する
					BTM::Path.check_peak(btmw_path.steps)

					if btmw_path.steps.count >= 3
						btmw_path.steps[1..-1].each do |s|
							if s.min_max == :mark_min || s.min_max == :mark_max
								route.tour_plan_points.create(
									point: s.point_geos,
									distance: s.distance_from_start,
									pass: true
									)
							end
						end
					end
				end

				# 分岐点の追加
				btmw_node = btmw_route.path_list[-1].end
				route.tour_plan_points.create(
					point: btmw_node.point_geos,
					direction: TourPlanPoint.direction_with_node_info(btmw_node.info),
					pass: false
					)
			end
		end

		# 既存データの反映
		old_index = 0
		@plan.tour_plan_routes.each do |route|
			route.tour_plan_points.each do |node|
				old_index_tmp = old_index
				while old_index_tmp < points_old.count
					if points_old[old_index_tmp].point == node.point
						orig = points_old[old_index_tmp]
						node.name = orig.name
						node.comment = orig.comment
						node.rest_time = orig.rest_time
						node.target_speed = orig.target_speed
						node.limit_speed = orig.limit_speed

						if ! orig.direction.nil? && ! orig.direction.empty?
							node.direction = orig.direction
						end

						node.save

						old_index = old_index_tmp + 1

						break
					end

					old_index_tmp += 1
				end
			end
		end
	end

	def setup_plan
		limit_speed = 15.0
		target_speed = 15.0
		offset = 0.0

		@plan.tour_plan_routes.each.with_index do |route, i|
			@tour.routes << BTM::Route.new
			@tour.routes.last.index = i + 1

			# URL 解析
			route.tour_plan_paths.each do |path|
				next if path.google_map_url.nil? || path.google_map_url.empty?
				@tour.routes.last.path_list.concat(@parser.parse_uri(path.google_map_url).path_list)
			end

			# ルート探索
			begin
				@tour.routes.last.search_route(TourPlanCache, TourPlanCache)
			rescue => e
				TourPlan::logger.fatal(e.inspect)
				raise e
			end

			# ラインの設定
			begin
				steps = @tour.routes.last.flatten.map {|s| s.point_geos }
			rescue => e
				TourPlan::logger.fatal(e.inspect)
				raise e
			end
			route.private_line = BTM.factory.line_string(steps)
			route.private_line_will_change!

			ExclusionArea.all.each do |area|
				steps.delete_if do |p|
					pt1 = BTM::Point.new(area.point.y, area.point.x)
					pt2 = BTM::Point.new(p.y, p.x)
					pt1.distance(pt2) < area.distance
				end
			end

			route.public_line = BTM.factory.line_string(steps)
			route.public_line_will_change!

			route.save!

			# 距離の算出
			@tour.routes.last.path_list.each do |path|
				path.set_start_end
			end
			@tour.routes.last.check_distance_from_start(offset)
			offset = @tour.routes.last.path_list.last.end.distance_from_start

			# ノード情報の割り当て
			index = 0
			way_point_index = 1
			route.tour_plan_points.each do |node|
				if node.limit_speed && node.limit_speed > 0.0
					limit_speed = node.limit_speed
				end

				if node.target_speed && node.target_speed > 0.0
					target_speed = node.target_speed
				end

				if node.pass
					path = @tour.routes.last.path_list[index - 1]

					new_path = BTM::Path.new
					new_path.start = BTM::Point.new(node.point.y, node.point.x, node.point.z)
					new_path.start.info = BTM::NodeInfo.new
					new_path.end = path.end
					path.end = new_path.start

					node.tmp_info = new_path.start

					peak_index = path.steps.find_index do |s|
							s.distance_from_start.to_i == node.distance \
								&& s.point_geos == node.point
						end
					new_path.steps.concat(path.steps.slice!((peak_index + 1)..-1))
					new_path.start.distance_from_start = node.distance
					new_path.start.ele = node.point.z

					@tour.routes.last.path_list.insert(index, new_path)

					node.tmp_info.info.text = "▲ : " + (node.comment || "")

				else
					if index == 0
						node.tmp_info = @tour.routes.last.path_list[0].start
					else
						node.tmp_info = @tour.routes.last.path_list[index - 1].end
					end

					if node.tmp_info
						info = node.tmp_info.info
						info.text = "★#{way_point_index} : " + (node.comment || "") 
						way_point_index += 1
					end
				end

				if node.tmp_info
					info = node.tmp_info.info

					info.name = node.name
					info.road = node.road
					info.orig = node.dir_src
					info.dest = node.dir_dest
					info.limit_speed = limit_speed
					info.target_speed = target_speed
					info.pass = node.pass

					ExclusionArea.all.each do |area|
						pt1 = BTM::Point.new(area.point.y, area.point.x)
						pt2 = BTM::Point.new(node.point.y, node.point.x)
						if pt1.distance(pt2) < area.distance
							info.hide = true
							break
						end
					end

					if node.rest_time
						info.rest_time = node.rest_time
					end
				end

				if index >= @tour.routes.last.path_list.count
					break
				end
				index += 1
			end
		end
	end

	def calculate_additional_info
		# 獲得標高の保存
		@plan.elevation = @tour.total_elevation
		@plan.save!
	end

	def setup_resource_management
		if @plan.resource_set
			@plan.resource_set.resource_entries.each do |res|
				@tour.resources << BTM::Resource.new(
					res.resource.name,
					res.amount,
					res.recovery_interval * 3600,
					res.buffer
					)
			end

			@plan.resource_set.device_entries.each do |dev|
				@tour.schedule << BTM::Schedule.new(
					"#{dev.device.name} #{dev.purpose} 交換",
					dev.use_on_start ? @tour.start_date : dev.start_time,
					dev.device.interval * 3600,
					dev.device.resource.name,
					dev.device.consumption
					)
			end
		end
	end

	def generate_plan
		context = BTM::PlanContext.new(@tour, nil, nil, @option)
		context.each_page do |pc, i, page_max|
			context.each_node do |node|
				# noting to do
			end

			context.update_resource_status do
				# noting to do
			end
		end
	end

	def generate_html(public_pdf)
		pdf_path = nil
		if public_pdf
			pdf_path = @plan.public_pdf_path()
			@renderer.option[:enable_hide] = true
		else
			pdf_path = @plan.pdf_path()
			@renderer.option[:enable_hide] = false
		end

		html_path = pdf_path.sub(/\.pdf$/, ".html")

		begin
			@renderer.render(@tour, html_path)
		rescue => e
			TourPlan::logger.fatal(e.inspect)
			TourPlan::logger.fatal(e.backtrace)
			raise e
		end
	end

	def generate_pdf(public_pdf)
		pdf_path = nil
		if public_pdf
			pdf_path = @plan.public_pdf_path()
		else
			pdf_path = @plan.pdf_path()
		end

		html_path = @plan.pdf_path().sub(/\.pdf$/, ".html")

		# PDF の生成
		FileUtils.mkdir_p(File.dirname(pdf_path))
		system("wkhtmltopdf --disable-smart-shrinking -s A4 -O Landscape -L 25mm -R 25mm -T 4mm -B 4mm #{html_path} #{pdf_path}")
	end

	def cleanup
		html_path = @plan.pdf_path().sub(/\.pdf$/, ".html")
		File.delete(html_path)

		html_path = @plan.public_pdf_path().sub(/\.pdf$/, ".html")
		File.delete(html_path)

		Dir.glob(File.join(File.dirname(html_path), "*.png")) do |path|
			File.delete(path)
		end
	end

	def save_node_infos
		# 各ノードの情報の保存
		@plan.tour_plan_routes.each do |route|
			route.tour_plan_points.each do |pt|
				next unless pt.tmp_info

				pt.target_time = pt.tmp_info.time_target
				pt.limit_time = pt.tmp_info.time
				pt.distance = pt.tmp_info.distance_from_start
				pt.point = BTM.factory.point(pt.point.x, pt.point.y, pt.tmp_info.ele)
				pt.save!
			end
		end
	end

	def plot_whole_altitude_image
		# 全体画像の生成
		ExclusionArea.all.each do |area|
			pt = BTM::Point.new(area.point.y, area.point.x)
			@tour.delete_by_distance(pt, area.distance)
		end

		min, max = *@tour.elevation_minmax
		min ||= 0
		max ||= 1000

		FileUtils.mkdir_p(File.dirname(@plan.altitude_graph_path))
		@plotter.distance_offset = 0.0
		@plotter.waypoint_offset = 0
		@plotter.distance_max = (@tour.total_distance + 10.0).to_i
		@plotter.elevation_min = (min / 100) * 100 - 100
		@plotter.elevation_max = [@plotter.elevation_min + 1100, ((max - 1) / 100 + 1) * 100].max + 100
		@plotter.label = true
		@plotter.plot(@tour, @plan.altitude_graph_path)
	end
end

class TourPlan < ActiveRecord::Base
	has_many :tour_plan_routes, -> { order("position ASC") }
	has_many :tour_results, -> { order("start_time DESC") }
	belongs_to :resource_set

	def self.list_all(user, page)
		if user.can? :edit, TourPlan
			TourPlan.paginate(page: page, per_page: 10).order("created_at DESC")
		else
			TourPlan.paginate(page: page, per_page: 10).where("published = true").order("created_at DESC")
		end
	end

	def self.page_for(user, id)
		tour = find_with_auth(user, id)
		if tour
			(TourPlan.where(["created_at >= ?", tour.created_at]).count - 1) / 10 + 1
		else
			1
		end
	end

	def self.time_utc(tz_name, time)
		time = ActiveSupport::TimeZone.find_tzinfo(tz_name).local_to_utc(time)
		Time.new(2000, 1, 1, time.hour, time.min, 0, 0)
	end

	def self.time_local(tz_name, time)
		time = ActiveSupport::TimeZone.find_tzinfo(tz_name).utc_to_local(time)
		Time.new(2000, 1, 1, time.hour, time.min, 0, 0)
	end

	def plan_time_utc(time)
		TourPlan.time_utc(time_zone, time)
	end

	def plan_time_local(time)
		TourPlan.time_local(time_zone, time)
	end

	def start_time_utc
		plan_time_utc(start_time)
	end

	def start_time_local
		plan_time_local(start_time)
	end

	def self.create_with_auth(user, attr_plan, attr_path)
		if user.can? :edit, TourPlan
			attr_plan[:start_time] = time_utc(attr_plan[:time_zone], attr_plan[:start_time])

			plan = TourPlan.new(attr_plan)
			plan.tour_plan_routes.build(name: attr_plan[:name])
			plan.tour_plan_routes[0].tour_plan_paths.build(attr_path)
			plan.save!

			create_points(user, plan.id)

			plan
		else
			nil
		end
	end

	def self.destroy_with_auth(user, id)
		if user.can?(:edit, TourPlan)
			TourPlan.where(["id = ?", id]).delete_all
		end
	end

	def self.edit_route_with_auth(user, id)
		if user.can? :edit, TourPlan
			plan = TourPlan.find(id)
			plan.start_time = plan.start_time_local
			plan
		else
			nil
		end
	end

	def self.edit_point_with_auth(user, id, page)
		if user.can? :edit, TourPlan
			TourPlanRoute.where(["tour_plan_id = ?", id]).paginate(page: page, per_page: 1).order("position ASC")
		else
			nil
		end
	end

	def self.find_with_auth(user, id)
		if user.can? :edit, TourPlan
			plan = TourPlan.find(id)
		else
			plan = TourPlan.where("published = 'true'").find(id)
		end

		if plan
			plan.start_time = plan.start_time_local
		end

		plan
	end

	def self.update_route_with_auth(user, id, attr, routes, paths)
		if user.can?(:edit, TourPlan)
			attr[:start_time] = time_utc(attr[:time_zone], attr[:start_time])
			TourPlan.where(["id = ?", id]).update_all(attr)

			routes.each do |key, value|
				TourPlanRoute.where(["id = ?", key]).update_all(value)
			end

			paths.each do |key, value|
				TourPlanPath.where(["id = ?", key]).update_all(value)
			end
		end
	end

	def self.update_point_with_auth(user, points)
		if user.can?(:edit, TourPlan)
			points.each do |key, value|
				attr = value.dup

				TourPlanPoint.pack_direction(attr)

				[:target_speed, :limit_speed, :rest_time].each do |c|
					if attr[c] == "" || attr[c].nil?
						attr[c] = nil
					end
				end

				TourPlanPoint.where(["id = ?", key]).update_all(attr)
			end

			begin
				id = TourPlanPoint.find(points.first[0]).tour_plan_route.tour_plan.id

				generator = TourPlanGenerator.new(id, false)
				generator.setup_plan
				generator.calculate_additional_info
				generator.setup_resource_management
				generator.generate_plan
				generator.save_node_infos
			rescue => e
				# nothing to do
				raise e
			end
		end
	end

	def self.create_route(user, id, name, url)
		plan = edit_route_with_auth(user, id)
		if plan
			route = plan.tour_plan_routes.create(name: name)
			route.tour_plan_paths.create(google_map_url: url)
		end
	end

	def self.create_points(user, id)
		if user.can?(:edit, TourPlan)
			begin
				generator = TourPlanGenerator.new(id, false)
				generator.create_nodes
				generator.setup_plan
				generator.calculate_additional_info
				generator.setup_resource_management
				generator.generate_plan
				generator.save_node_infos
			rescue => e
				# nothing to do
				raise e
			end
		end
	end

	def self.generate(id, make_pdf)
		begin
			generator = TourPlanGenerator.new(id, make_pdf)
			generator.setup_plan
			generator.calculate_additional_info
			generator.setup_resource_management

			generator.generate_html(false)
			if make_pdf
				generator.generate_pdf(false)
			end

			generator.generate_html(true)
			if make_pdf
				generator.generate_pdf(true)
			end

			generator.cleanup
			generator.save_node_infos
			generator.plot_whole_altitude_image
		rescue => e
			# nothing to do
			raise e
		end
	end

	def self.geneate_with_auth(user, id, make_pdf)
		if user.can?(:edit, TourPlan)
			generate(id, make_pdf)
		end
	end

	def altitude_graph_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, altitude_graph_url)
	end

	def altitude_graph_url
		"/generated/tour_plan/altitude_graph/#{id}.png"
	end

	def pdf_name()
		name = id.to_s + ".pdf"
	end

	def pdf_path()
		private_root = File.join(Rails.root, "private")
		File.join(private_root, "tour_plan/pdf/#{pdf_name()}")
	end

	def public_pdf_url()
		"/generated/tour_plan/pdf/#{pdf_name()}"
	end

	def public_pdf_path()
		public_root = File.join(Rails.root, "public")
		File.join(public_root, public_pdf_url())
	end

	def to_tour(is_public_data)
		tour = BTM::Tour.new
		tour.start_date = self.start_time_local
		tour.name = self.name

		tour_plan_routes.each do |route|
			tour.routes << BTM::Route.new
			tour.routes.last.index = tour.routes.count
			tour.routes.last.path_list << BTM::Path.new

			route.tour_plan_points.each do |node|
				wpt = BTM::Point.new(node.point.y, node.point.x, node.point.z)
				tour.routes.last.path_list.last.way_points << wpt
			end

			line = nil
			if is_public_data
				line = route.public_line
			else
				line = route.private_line
			end

			line.points.each do |p|
				pt = BTM::Point.new(p.y, p.x, p.z)
				tour.routes.last.path_list.last.steps << pt
			end
		end

		tour.set_start_end
		tour
	end

	def to_gpx(is_public_data)
		tour = self.to_tour(is_public_data)
		io = StringIO.new("", "w")
		BTM::GpxStream.write_routes_to_stream(io, tour)
		io.string
	end

	def distance(is_public_data)
		column_name = is_public_data ? "public_line" : "private_line"
		ret = TourPlan.find_by_sql([<<-EOS, id])[0].length
SELECT ST_Length(t.path, false) as length FROM
	(SELECT ST_Collect(#{column_name}) AS path FROM tour_plan_routes WHERE tour_plan_id = ?) as t
		EOS
		ret.to_i / 1000
	end

	def self.toggle_visible(user, id)
		if user.can? :edit, TourPlan
			TourPlan.where(["id = ?", id]).update_all("published = CASE WHEN published = TRUE THEN FALSE ELSE TRUE END")
		end
	end
end
