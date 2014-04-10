class TourPlanPoint < ActiveRecord::Base
	belongs_to :tour_plan_route
	acts_as_list scope: :tour_plan_route
end
