class TourGoEvent < ActiveRecord::Base
	belongs_to :tour_go
	belongs_to :tour_plan_point

	enum event_type: { pass_point: 0 }
end
