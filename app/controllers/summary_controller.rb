class SummaryController < ApplicationController
	before_action :authenticate_user!, only: [
		:edit_user,
		:management,
		:create_exclusion_area, :destroy_exclusion_area, :update_exclusion_area,
		:update_resources, :destroy_resource,
		:update_devices, :destroy_device,
		:destroy_resource_entry,
		:destroy_device_entry,
		:create_resource_set, :edit_resource_set, :update_resource_set,
	]

	def index
	end

	def login
	end

	def edit_user
		User.update_role(current_user, params[:user])
		redirect_to(action: :management)
	end

	def management
		@users = User.all
		@areas = ExclusionArea.all_with_auth(current_user_or_guest)

		@resources = Resource.all
		@devices = Device.all
		@resource_sets = ResourceSet.all

		if params.include?(:resource_set_id)
			@set = ResourceSet.find(params[:set_id])
		elsif @resource_sets.count > 0
			@set = @resource_sets[0]
		end
	end

	def create_exclusion_area
		attr = params[:exclusion_area].permit(:lat, :lon, :distance)
		ExclusionArea.create_with_auth(current_user_or_guest, attr)
		redirect_to(action: :management)
	end

	def destroy_exclusion_area
		ExclusionArea.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to(action: :management)
	end

	def update_exclusion_area
		attr = params[:update_exclusion_area].permit(:lat, :lon, :distance)
		ExclusionArea.update_with_auth(current_user_or_guest, params[:update_exclusion_area][:id], attr)
		redirect_to(action: :management)
	end

	def create_resource_set
		attr = params[:set_new].permit(:name)
		@set = ResourceSet.create(attr)

		@resources = Resource.all
		@devices = Device.all

		headers["Content-Type"] = "text/javascript"
		render(action: :edit_resource_set)
	end

	def edit_resource_set
		@set = ResourceSet.find(params[:set][:id])
		@resources = Resource.all
		@devices = Device.all
		headers["Content-Type"] = "text/javascript"
	end
end
