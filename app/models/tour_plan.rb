# coding: utf-8

require "bicycle_tour_manager"

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
			plan = TourPlan.find(id)

			points_old = []
			plan.tour_plan_routes.each do |route|
				points_old += route.tour_plan_points
				route.tour_plan_points.destroy_all
			end

			parser = BTM::GoogleMapUriParser.new(TourPlanCache)
			plan.tour_plan_routes.each do |route|
				route.tour_plan_paths.each do |path|
					next if path.google_map_url.nil? || path.google_map_url.empty?

					btmw_route = parser.parse_uri(path.google_map_url)

					btmw_route.path_list.each.with_index do |btmw_path, i|
						next if route.tour_plan_points.count > 0 && i == 0
						route.tour_plan_points.create(point: btmw_path.start.point_geos)
					end

					route.tour_plan_points.create(point: btmw_route.path_list[-1].end.point_geos)
				end
			end

			# 既存データの反映
			old_index = 0
			plan.tour_plan_routes.each do |route|
				route.tour_plan_points.each do |node|
					old_index_tmp = old_index
					while old_index_tmp < points_old.count
						if points_old[old_index_tmp].point == node.point
							orig = points_old[old_index_tmp]
							node.name = orig.name
							node.direction = orig.direction
							node.comment = orig.comment
							node.rest_time = orig.rest_time
							node.target_speed = orig.target_speed
							node.limit_speed = orig.limit_speed
							node.save

							old_index = old_index_tmp + 1

							break
						end

						old_index_tmp += 1
					end
				end
			end
		end
	end

	def self.generate(id)
		plan = TourPlan.find(id)

		parser = BTM::GoogleMapUriParser.new(TourPlanCache)

		tour = BTM::Tour.new
		tour.start_date = plan.start_time_local

		limit_speed = 15.0
		target_speed = 15.0

		plan.tour_plan_routes.each.with_index do |route, i|
			tour.routes << BTM::Route.new
			tour.routes.last.index = i + 1

			# URL 解析
			route.tour_plan_paths.each do |path|
				next if path.google_map_url.nil? || path.google_map_url.empty?
				tour.routes.last.path_list.concat(parser.parse_uri(path.google_map_url).path_list)
			end

			# ルート探索
			begin
				tour.routes.last.search_route(TourPlanCache, TourPlanCache)
			rescue => e
				logger.fatal(e.backtrace.join("\n"))
				return
			end

			# ラインの設定
			steps = tour.routes.last.flatten.map {|s| s.point_geos }
			route.private_line = BTM.factory.line_string(steps)

			ExclusionArea.all.each do |area|
				steps.delete_if do |p|
					pt1 = BTM::Point.new(area.point.y, area.point.x)
					pt2 = BTM::Point.new(p.y, p.x)
					pt1.distance(pt2) < area.distance
				end
			end

			route.public_line = BTM.factory.line_string(steps)

			route.save!

			# ノード情報の割り当て
			route.tour_plan_points.each.with_index do |node, i|
				if node.limit_speed && node.limit_speed > 0.0
					limit_speed = node.limit_speed
				end

				if node.target_speed && node.target_speed > 0.0
					target_speed = node.target_speed
				end

				info = BTM::NodeInfo.new
				info.text = "★#{i + 1} : " + (node.comment || "") 
				info.name = node.name
				info.road = node.road
				info.orig = node.dir_src
				info.dest = node.dir_dest
				info.limit_speed = limit_speed
				info.target_speed = target_speed

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

				if i < tour.routes.last.path_list.count
					node.tmp_info = tour.routes.last.path_list[i].steps[0]
					if node.tmp_info
						node.tmp_info.info = info
					end
				else
					node.tmp_info = tour.routes.last.path_list.last.steps[-1]
					if node.tmp_info
						node.tmp_info.info = info
					end
					break
				end
			end
		end

		# 付加情報の設定
		tour.set_start_end
		begin
			tour.check_distance_from_start
		rescue => e
			logger.fatal(e.backtrace.join("\n"))
			return
		end

		# 獲得標高の保存
		plan.elevation = tour.total_elevation
		plan.save!

		if plan.resource_set
			plan.resource_set.resource_entries.each do |res|
				tour.resources << BTM::Resource.new(
					res.resource.name,
					res.amount,
					res.recovery_interval * 3600,
					res.buffer
					)
			end

			plan.resource_set.device_entries.each do |dev|
				tour.schedule << BTM::Schedule.new(
					"#{dev.device.name} #{dev.purpose} 交換",
					dev.use_on_start ? tour.start_date : dev.start_time,
					dev.device.interval * 3600,
					dev.device.resource.name,
					dev.device.consumption
					)
			end
		end

		# 画像の生成
		plotter = BTM::AltitudePloter.new("gnuplot", File.join(Rails.root, "tmp"))
		plotter.font = File.join(Rails.root, "vendor/font/mikachan-p.ttf")

		# PDF の生成
		[true, false].each do |half|
			FileUtils.mkdir_p(File.dirname(plan.pdf_path(half)))
			FileUtils.mkdir_p(File.dirname(plan.public_pdf_path(half)))

			plotter.distance_max = half ? 100.0 : 160.0
			plotter.label = false

			html_path = plan.pdf_path(half).sub(/\.pdf$/, ".html")
			renderer = BTM::PlanHtmlRenderer.new(
				plotter,
				enable_hide: false,
				scale: (plan.planning_sheet_scale || 0.8),
				format: (half ? :half : :standard)
				)

			begin
				renderer.render(tour, html_path)
			rescue => e
				logger.fatal(e.backtrace.join("\n"))
				return
			end

			if half
				system("wkhtmltopdf --disable-smart-shrinking -s A6 -L 4mm -R 4mm -T 4mm -B 0mm #{html_path} #{plan.pdf_path(half)}")
			else
				system("wkhtmltopdf --disable-smart-shrinking -s A5 -O Landscape -L 4mm -R 4mm -T 4mm -B 0mm #{html_path} #{plan.pdf_path(half)}")
			end

			renderer.option[:enable_hide] = true
	
			begin
				renderer.render(tour, html_path)
			rescue => e
				logger.fatal(e.backtrace.join("\n"))
				return
			end

			if half
				system("wkhtmltopdf --disable-smart-shrinking -s A6 -L 4mm -R 4mm -T 4mm -B 0mm #{html_path} #{plan.public_pdf_path(half)}")
			else
				system("wkhtmltopdf --disable-smart-shrinking -s A5 -O Landscape -L 4mm -R 4mm -T 4mm -B 0mm #{html_path} #{plan.public_pdf_path(half)}")
			end

			File.delete(html_path)
			Dir.glob(File.join(File.dirname(html_path), "*.png")) do |path|
				File.delete(path)
			end
		end

		# 各ノードの情報の保存
		plan.tour_plan_routes.each do |route|
			route.tour_plan_points.each do |pt|
				pt.target_time = pt.tmp_info.time_target
				pt.limit_time = pt.tmp_info.time
				pt.distance = pt.tmp_info.distance_from_start
				pt.elevation = pt.tmp_info.ele
				pt.save!
			end
		end

		# 全体画像の生成
		ExclusionArea.all.each do |area|
			tour.delete_by_distance(area.point, area.distance)
		end

		min, max = *tour.elevation_minmax
		min ||= 0
		max ||= 1000

		FileUtils.mkdir_p(File.dirname(plan.altitude_graph_path))
		plotter.distance_offset = 0.0
		plotter.waypoint_offset = 0
		plotter.distance_max = (tour.total_distance + 10.0).to_i
		plotter.elevation_min = (min / 100) * 100 - 100
		plotter.elevation_max = [plotter.elevation_min + 1100, ((max - 1) / 100 + 1) * 100].max + 100
		plotter.label = true
		plotter.plot(tour, plan.altitude_graph_path)
	end

	def self.geneate_with_auth(user, id)
		if user.can?(:edit, TourPlan)
			generate(id)
		end
	end

	def altitude_graph_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, altitude_graph_url)
	end

	def altitude_graph_url
		"/generated/tour_plan/altitude_graph/#{id}.png"
	end

	def pdf_name(half)
		name = id.to_s + (half ? "_half" : "") + ".pdf"
	end

	def pdf_path(half)
		private_root = File.join(Rails.root, "private")
		File.join(private_root, "tour_plan/pdf/#{pdf_name(half)}")
	end

	def public_pdf_url(half)
		"/generated/tour_plan/pdf/#{pdf_name(half)}"
	end

	def public_pdf_path(half)
		public_root = File.join(Rails.root, "public")
		File.join(public_root, public_pdf_url(half))
	end

	def to_tour(is_public_data)
		tour = BTM::Tour.new
		tour.start_date = self.start_time_local
		tour.name = self.name

		tour_plan_routes.each do |route|
			tour.routes << BTM::Route.new
			tour.routes.last.path_list << BTM::Path.new

			line = nil
			if is_public_data
				line = route.public_line
			else
				line = route.private_line
			end

			line.points.each do |p|
				pt = BTM::Point.new(p.y, p.x)
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
