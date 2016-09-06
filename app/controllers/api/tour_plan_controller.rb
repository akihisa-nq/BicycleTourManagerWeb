module Api
	class TourPlanController < Api::BaseController
		def list
			tour_plans = TourPlan
				.all_with_auth(current_user, params[:offset], params[:limit])
				.map {|tour_plan| tour_plan.attributes }
			tour_plans.each { |tour_plan| filter_attributes_tour_plan(tour_plan) }
			render json: { tour_plans: tour_plans }.to_json
		end

		def show
			tour_plan = TourPlan
				.find_with_auth(current_user, params[:id])
			attrs = filter_attributes_tour_plan(tour_plan.attributes)

			if params["all"] == "1"
				attrs["routes"] = []
				tour_plan.tour_plan_routes.each do |route|
					attrs["routes"] << route.attributes
					attrs["routes"].last["points"] = []

					route.tour_plan_points.each do |point|
						attrs["routes"].last["points"] << point.attributes
					end
				end
			end

			render json: attrs.to_json
		end

		private

		def filter_attributes_tour_plan(tour_plan)
			tour_plan["published"] = tour_plan["published"] ? true : false
			tour_plan.delete("planning_sheet_scale")
			tour_plan
		end
	end
end
