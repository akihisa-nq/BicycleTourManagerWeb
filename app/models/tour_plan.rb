# coding: utf-8

require "bicycle_tour_manager"

class TourPlan < ActiveRecord::Base
	has_many :tour_plan_routes

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

	def self.create_with_auth(user, attr_plan, attr_path)
		if user.can? :edit, TourPlan
			attr_plan[:start_time] = ActiveSupport::TimeZone.find_tzinfo(attr_plan[:time_zone]).local_to_utc(attr_plan[:start_time])

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
			plan.start_time = ActiveSupport::TimeZone.find_tzinfo(plan.time_zone).utc_to_local(plan.start_time)
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
			plan.start_time = ActiveSupport::TimeZone.find_tzinfo(plan.time_zone).utc_to_local(plan.start_time)
		end

		plan
	end

	def self.update_route_with_auth(user, id, attr, routes, paths)
		if user.can?(:edit, TourPlan)
			attr[:start_time] = ActiveSupport::TimeZone.find_tzinfo(attr[:time_zone]).local_to_utc(attr[:start_time])
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

					btmw_route.path_list.each do |btmw_path|
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

	def self.geneate_with_auth(user, id)
		if user.can?(:edit, TourPlan)
			plan = TourPlan.find(id)

			parser = BTM::GoogleMapUriParser.new(TourPlanCache)

			tour = BTM::Tour.new

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
				tour.routes.last.search_route(TourPlanCache, TourPlanCache)

				# 距離の計算など
				tour.routes.last.path_list.each do |p|
					p.check_peak
					p.check_distance_from_start
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
						info.rest_time = (node.rest_time * 3600).to_i
					end

					if i < tour.routes.last.path_list.count
						tour.routes.last.path_list[i].steps[0].info = info
					else
						tour.routes.last.path_list.last.steps[-1].info = info
						break
					end
				end
			end

			tour.set_start_end

			# 画像の生成
			plotter = BTM::AltitudePloter.new("gnuplot", File.join(Rails.root, "tmp"))
			plotter.elevation_max = 1100
			plotter.elevation_min = -100
			plotter.font = File.join(Rails.root, "vendor/font/mikachan-p.ttf")

			# PDF の生成
			FileUtils.mkdir_p(File.dirname(plan.pdf_path))
			FileUtils.mkdir_p(File.dirname(plan.public_pdf_path))

			tour.routes.each.with_index do |r, i|
				plotter.distance_max = 120.0
				plotter.plot(r, File.join(File.dirname(plan.pdf_path), "PC#{i+1}.png"))
			end

			html_path = plan.pdf_path.sub(/\.pdf$/, ".html")
			renderer = BTM::PlanHtmlRenderer.new(enable_hide: false)

			renderer.render(tour, html_path)
			system("wkhtmltopdf -s A5 -O Landscape -L 4mm -R 4mm -T 4mm  #{html_path} #{plan.pdf_path}")

			renderer.option[:enable_hide] = true
			renderer.render(tour, html_path)
			system("wkhtmltopdf -s A5 -O Landscape -L 4mm -R 4mm -T 4mm  #{html_path} #{plan.public_pdf_path}")

			File.delete(html_path)
			Dir.glob(File.join(File.dirname(html_path), "*.png")) do |path|
				File.delete(path)
			end

			# 獲得標高の保存
			plan.elevation = tour.total_elevation
			plan.save!

			# 全体画像の生成
			ExclusionArea.all.each do |area|
				tour.delete_by_distance(area.point, area.distance)
			end

			FileUtils.mkdir_p(File.dirname(plan.altitude_graph_path))
			plotter.distance_max = (tour.total_distance + 10.0).to_i
			plotter.plot(tour, plan.altitude_graph_path)
		end
	end

	def altitude_graph_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, altitude_graph_url)
	end

	def altitude_graph_url
		"/generated/tour_plan/altitude_graph/#{id}.png"
	end

	def pdf_path
		private_root = File.join(Rails.root, "private")
		File.join(private_root, "tour_plan/pdf/#{id}.pdf")
	end

	def public_pdf_url
		"/generated/tour_plan/pdf/#{id}.pdf"
	end

	def public_pdf_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, public_pdf_url)
	end

	def to_tour(is_public_data)
		tour = BTM::Tour.new
		tour.start_date = self.start_time
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
end
