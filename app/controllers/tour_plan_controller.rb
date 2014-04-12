class TourPlanController < ApplicationController
	before_action :authenticate_user!, only: [
		:create, :destroy, :edit, :update, :toggle_visible,
		:destroy_path
	]

	def index
		@tour_plans = TourPlan.list_all(current_user_or_guest, params[:page])
	end

	def create
		attr = params[:tour_plan].permit(:name, :google_map_url)
		plan = TourPlan.create_with_auth(current_user_or_guest, attr[:name], attr[:google_map_url])
		redirect_to( action: :edit, id: plan.id )
	end

	def destroy
		TourPlan.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to( action: :list, page: params[:page] )
	end

	def edit
		@tour_plan = TourPlan.edit_with_auth(current_user_or_guest, params[:id])
	end

	def update
		TourPlan.update_with_auth(
			current_user_or_guest,
			params[:id],
			params[:tour_plan].permit(:name),
			params[:route],
			params[:path],
			)

		attr = params[:route_new].permit(:name, :google_map_url)
		if ! attr[:name].empty? || ! attr[:google_map_url].empty?
			TourPlan.create_route(current_user_or_guest, params[:id], attr[:name], attr[:google_map_url])
		end

		params[:path_new].each do |key, value|
			if ! value[:google_map_url].empty?
				TourPlanPath.create_with_auth(current_user_or_guest, key, value)
			end
		end

		redirect_to( action: :edit, id: params[:id] )
	end

	def show
		@tour_plan = TourPlan.find_with_auth(current_user_or_guest, params[:id])
	end

	def toggle_visible
	end

	def destroy_path
		TourPlanPath.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to(action: :edit, id: params[:tour_plan_id])
	end
end
