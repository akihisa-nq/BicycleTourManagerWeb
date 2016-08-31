module Api
	class TourPlanController < Api::BaseController
		def list
			tour_plans = TourPlan.all_with_auth(current_user, params[:offset], params[:limit]).map {|tour_plan| tour_plan.attributes }
			tour_plans.each do |tour_plan|
				tour_plan["published"] = tour_plan["published"] ? true : false
				tour_plan.delete("planning_sheet_scale")
			end
			render json: { tour_plans: tour_plans }.to_json
		end
	end
end
