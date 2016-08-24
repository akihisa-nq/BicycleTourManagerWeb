class TourPlanUpHill < ActiveRecord::Base
	belongs_to :tour_plan_point
	acts_as_list scope: :tour_plan_point
end
