class TourPlanPath < ActiveRecord::Base
	belongs_to :tour_plan_route
	acts_as_list scope: :tour_plan_route

	def self.create_with_auth(user, tour_plan_route_id, attr)
		if user.can?(:edit, TourPlan)
			attr_ = attr.dup
			attr_[:tour_plan_route_id] = tour_plan_route_id
			TourPlanPath.create(attr_)
		end
	end

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, TourPlan)
			path = TourPlanPath.find(id)
			route = path.tour_plan_route

			path.delete
			if route.tour_plan_paths.count == 0
				route.delete
			end
		end
	end
end
