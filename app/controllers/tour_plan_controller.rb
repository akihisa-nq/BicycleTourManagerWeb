class TourPlanController < ApplicationController
	before_action :authenticate_user!, only: [
		:create, :destroy, :edit,
		:toggle_visible,
	]

	def index
		@tour_plans = TourPlan.list_all(current_user_or_guest, params[:page])
	end

	def create
		attr = params[:tour_plan].permit(:name, :google_map_url)
		plan = TourPlan.create_with_auth(current_user_or_guest, attr[:name], attr[:google_map_url])
		redirect_to( action: :edit, id: plan.id )
	end
end
