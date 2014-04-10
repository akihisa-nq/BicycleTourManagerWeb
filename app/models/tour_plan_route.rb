class TourPlanRoute < ActiveRecord::Base
	belongs_to :tour_plan
	acts_as_list scope: :tour_plan

	has_many :tour_plan_points, -> { order("position ASC") }
	has_many :tour_plan_paths, -> { order("position ASC") }
end
