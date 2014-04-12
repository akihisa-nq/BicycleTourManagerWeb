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

	def self.edit_with_auth(user, id)
		if user.can? :edit, TourPlan
			TourPlan.find(id)
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

	def self.update_with_auth(user, id, attr, routes, paths)
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

	def self.create_route(user, id, name, url)
		plan = edit_with_auth(user, id)
		if plan
			route = plan.tour_plan_routes.create(name: name)
			route.tour_plan_paths.create(google_map_url: url)
		end
	end
end
