class ManagementController < ApplicationController
	before_action :authenticate_user! # all actions of this controller

	def index
		@users = User.all
		@areas = ExclusionArea.all_with_auth(current_user_or_guest)

		fetch_all_with_set
	end

	def edit_user
		User.update_role(current_user, params[:user])
		redirect_to(action: :management)
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

	def destroy_resource
		Resource.destroy_with_auth(current_user_or_guest, params[:id])

		fetch_all
		headers["Content-Type"] = "text/javascript"
		render(action: :update_resources)
	end

	def update_resources
		attr = params[:res_new].permit(:name)
		Resource.create_with_auth(current_user_or_guest, attr)

		(params[:res] || []).each do |id, attr|
			Resource.update_with_auth(current_user_or_guest, id, attr)
		end

		fetch_all
		headers["Content-Type"] = "text/javascript"
	end

	def destroy_device
		Device.destroy_with_auth(current_user_or_guest, params[:id])

		fetch_all
		headers["Content-Type"] = "text/javascript"
		render(action: :update_devices)
	end

	def update_devices
		attr = params[:dev_new].permit(:name, :resource_id, :interval, :consumption)
		Device.create_with_auth(current_user_or_guest, attr)

		(params[:dev] || []).each do |id, attr|
			Device.update_with_auth(current_user_or_guest, id, attr)
		end

		fetch_all
		headers["Content-Type"] = "text/javascript"
	end

	def create_resource_set
		attr = params[:set_new].permit(:name)
		@set = ResourceSet.create_with_auth(current_user_or_guest, attr)

		fetch_all_with_set

		headers["Content-Type"] = "text/javascript"
		render(action: :edit_resource_set)
	end

	def edit_resource_set
		if params[:delete]
			ResourceSet.destroy_with_auth(current_user_or_guest, params[:set][:id])
		else
			@set = ResourceSet.edit_with_auth(current_user_or_guest, params[:set][:id])
		end

		fetch_all_with_set

		headers["Content-Type"] = "text/javascript"
	end

	def update_resource_set
		ResourceSet.update_with_auth(
			current_user_or_guest,
			params[:id],
			params[:set].permit(:name),
			params[:res_entry] || [],
			params[:res_entry_new].permit(:resource_id, :amount, :buffer, :recovery_interval),
			params[:dev_entry] || [],
			params[:dev_entry_new].permit(:purpose, :device_id)
			)
		@set = ResourceSet.edit_with_auth(current_user_or_guest, params[:id])
		fetch_all_with_set
		headers["Content-Type"] = "text/javascript"
		render(action: :edit_resource_set)
	end

	def destroy_resource_entry
		ResourceEntry.destroy_with_auth(current_user_or_guest, params[:id])

		fetch_all_with_set
		headers["Content-Type"] = "text/javascript"
		render(action: :edit_resource_set)
	end

	def destroy_device_entry
		DeviceEntry.destroy_with_auth(current_user_or_guest, params[:id])

		fetch_all_with_set
		headers["Content-Type"] = "text/javascript"
		render(action: :edit_resource_set)
	end

	private

	def res_set_find_specified_or_first
		if @set.nil? && params.include?(:resource_set_id)
			@set = ResourceSet.edit_with_auth(current_user_or_guest, params[:resource_set_id])
		end

		if @set.nil?
			@set = ResourceSet.first_with_auth(current_user_or_guest)
		end
	end

	def fetch_all
		@resources = Resource.all_with_auth(current_user_or_guest)
		@devices = Device.all_with_auth(current_user_or_guest)
		res_set_find_specified_or_first
	end

	def fetch_all_with_set
		@resource_sets = ResourceSet.all_with_auth(current_user_or_guest)
		fetch_all
	end
end
