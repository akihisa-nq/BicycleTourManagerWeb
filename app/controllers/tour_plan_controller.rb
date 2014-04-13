class TourPlanController < ApplicationController
	before_action :authenticate_user!, only: [
		:create, :destroy, :toggle_visible,
		:edit_path, :update_path, :destroy_path,
		:edit_node, :update_node, :destroy_node,
	]

	def index
		@tour_plans = TourPlan.list_all(current_user_or_guest, params[:page])
	end

	def create
		attr = params[:tour_plan].permit(:name, :google_map_url)
		plan = TourPlan.create_with_auth(current_user_or_guest, attr[:name], attr[:google_map_url])
		redirect_to( action: :edit_path, id: plan.id )
	end

	def destroy
		TourPlan.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to( action: :index, page: params[:page] )
	end

	def show
		@tour_plan = TourPlan.find_with_auth(current_user_or_guest, params[:id])
	end

	def toggle_visible
	end

	def edit_path
		@tour_plan = TourPlan.edit_route_with_auth(current_user_or_guest, params[:id])
	end

	def update_path
		TourPlan.update_route_with_auth(
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

		TourPlan.create_points(current_user_or_guest, params[:id])

		redirect_to( action: :edit_path, id: params[:id] )
	end

	def destroy_path
		TourPlanPath.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to(action: :edit_path, id: params[:tour_plan_id])
	end

	def edit_node
		@tour_routes = TourPlan.edit_point_with_auth(current_user_or_guest, params[:id], params[:page])
		@tour_route = @tour_routes[0]
	end

	def update_node
		TourPlan.update_point_with_auth(current_user_or_guest, params[:node])
		redirect_to( action: :edit_node, id: params[:id], page: params[:page] )
	end
end
