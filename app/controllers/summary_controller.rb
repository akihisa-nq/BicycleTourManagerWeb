class SummaryController < ApplicationController
	def index
		@tour_go = TourGo.all_with_auth(current_user_or_guest, 0, 1)[0]
		if @tour_go
			if @tour_go.tour_go_events.last
				last_item = @tour_go.tour_go_events.select {|e| e.pass_point? }.last
				@center = last_item.tour_plan_point
				@date = last_item.occured_on
			else
				@center = @tour_go.tour_plan.tour_plan_routes.first.tour_plan_points.first
				@date = @tour_go.start_time
			end
		end
	end

	def login
	end
end
