class TourPlanController < ApplicationController
	before_action :authenticate_user!, only: [
		:create, :destroy, :toggle_visible, :generate,
		:edit_path, :update_path, :destroy_path,
		:edit_node, :update_node, :destroy_node,
	]

	def index
		@tour_plans = TourPlan.list_all(current_user_or_guest, params[:page])
	end

	def create
		attr_plan = params[:tour_plan].permit(:name, :time_zone, :resource_set_id)
		attr_plan[:start_time] = Time.new(
			2000, 1, 1,
			params[:tour_plan]["start_time(4i)"].to_i,
			params[:tour_plan]["start_time(5i)"].to_i,
			0, 0
			)
		attr_path = params[:tour_path].permit(:google_map_url)
		plan = TourPlan.create_with_auth(current_user_or_guest, attr_plan, attr_path)
		redirect_to( action: :edit_path, id: plan.id )
	end

	def destroy
		TourPlan.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to( action: :index, page: params[:page] )
	end

	def show
		@tour_plan = TourPlan.find_with_auth(current_user_or_guest, params[:id])
		render(layout: "tour_viewer")
	end

	def show_gpx
		tour_plan = TourPlan.find_with_auth(current_user_or_guest, params[:id])
		headers["Content-Type"] = "application/xml; charset=UTF-8"
		render(:body => tour_plan.to_gpx(true), :layout => false)
	end

	def show_private_gpx
		tour_plan = TourPlan.edit_route_with_auth(current_user_or_guest, params[:id])
		headers["Content-Type"] = "application/xml; charset=UTF-8"
		headers["Content-Disposition"] = %Q|attachment; filename="route.gpx"|
		render(:body => tour_plan.to_gpx(false), :layout => false)
	end

	def show_pdf
		tour_plan = TourPlan.edit_route_with_auth(current_user_or_guest, params[:id])
		headers["Content-Type"] = "application/pdf"
		render(:body => File.open(tour_plan.pdf_path(), "rb") {|f| f.read }, :layout => false)
	end

	def toggle_visible
		TourPlan.toggle_visible(current_user_or_guest, params[:id])
		redirect_to(action: :index, id: nil, page: TourPlan.page_for(current_user_or_guest, params[:id]), anchor: "tour_item_#{params[:id]}")
	end

	def generate
		TourPlan.geneate_with_auth(current_user_or_guest, params[:id], params[:make_pdf] == "1")
		redirect_to( action: :show, id: params[:id])
	end

	def edit_path
		@tour_plan = TourPlan.edit_route_with_auth(current_user_or_guest, params[:id])
	end

	def update_path
		attr_plan = params[:tour_plan].permit(:name, :time_zone, :resource_set_id, :planning_sheet_scale)
		attr_plan[:start_time] = Time.new(
			2000, 1, 1,
			params[:tour_plan]["start_time(4i)"].to_i,
			params[:tour_plan]["start_time(5i)"].to_i,
			0, 0
			)

		TourPlan.update_route_with_auth(
			current_user_or_guest,
			params[:id],
			attr_plan,
			params[:route] || [],
			params[:path] || [],
			)

		attr = params[:route_new].permit(:name, :google_map_url)
		if ! attr[:name].empty? || ! attr[:google_map_url].empty?
			TourPlan.create_route(current_user_or_guest, params[:id], attr[:name], attr[:google_map_url])
		end

		params[:path_new].each do |key, value|
			if ! value[:google_map_url].empty?
				TourPlanPath.create_with_auth(current_user_or_guest, key, value.permit(:google_map_url))
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
		@tour_route.set_point_lines
	end

	def update_node
		TourPlan.update_point_with_auth(current_user_or_guest, params[:node] || [])
		redirect_to( action: :edit_node, id: params[:id], page: params[:page] )
	end

	def tile
		headers["Content-Type"] = "image/png"
		render(body: TourPlanTile.tile(params[:x].to_i, params[:y].to_i, params[:zoom].to_i, true))
	end
end
