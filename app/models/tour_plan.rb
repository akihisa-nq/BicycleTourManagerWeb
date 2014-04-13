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

	def self.create_with_auth(user, name, url)
		if user.can? :edit, TourPlan
			plan = TourPlan.new(name: name)
			plan.tour_plan_routes.build(name: name)
			plan.tour_plan_routes[0].tour_plan_paths.build(google_map_url: url)
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
			TourPlan.find(id)
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
			TourPlan.find(id)
		else
			TourPlan.where("published = 'true'").find(id)
		end
	end

	def self.update_route_with_auth(user, id, attr, routes, paths)
		if user.can?(:edit, TourPlan)
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
end
