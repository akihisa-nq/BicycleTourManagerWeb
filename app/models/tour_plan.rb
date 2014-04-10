class TourPlan < ActiveRecord::Base
	has_many :tour_plan_routes
end
