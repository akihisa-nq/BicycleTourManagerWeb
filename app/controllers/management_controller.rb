class ManagementController < ApplicationController
	before_action :authenticate_user! # all actions of this controller

	def index
		@users = User.all
		@areas = ExclusionArea.all_with_auth(current_user_or_guest)

		@resource_sets = ResourceSet.all
		fetch_all
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
		Resource.where(["id = ?", params[:id]]).delete_all

		fetch_all
		headers["Content-Type"] = "text/javascript"
		render(action: :update_resources)
	end

	def update_resources
		attr = params[:res_new].permit(:name)
		unless attr[:name].empty?
			Resource.create(attr)
		end

		fetch_all
		headers["Content-Type"] = "text/javascript"
	end

	def destroy_device
		Device.where(["id = ?", params[:id]]).delete_all

		fetch_all
		headers["Content-Type"] = "text/javascript"
		render(action: :update_devices)
	end

	def update_devices
		attr = params[:dev_new].permit(:name, :resource_id, :interval)
		unless attr[:name].empty? && attr[:resource_id].empty? && attr[:interval].empty?
			Device.create(attr)
		end

		fetch_all
		headers["Content-Type"] = "text/javascript"
	end

	def create_resource_set
		attr = params[:set_new].permit(:name)
		@set = ResourceSet.create(attr)

		@resource_sets = ResourceSet.all
		@resources = Resource.all
		@devices = Device.all

		headers["Content-Type"] = "text/javascript"
		render(action: :edit_resource_set)
	end

	def edit_resource_set
		if params[:delete]
			ResourceSet.where(["id = ?", params[:set][:id]]).delete_all
			fetch_all
		else
			@set = ResourceSet.find(params[:set][:id])
			@resources = Resource.all
			@devices = Device.all
		end

		@resource_sets = ResourceSet.all

		headers["Content-Type"] = "text/javascript"
	end

	private

	def res_set_find_specified_or_first
		if params.include?(:resource_set_id)
			ResourceSet.find(params[:resource_set_id])
		end

		if @set.nil? && ResourceSet.count > 0
			@set = ResourceSet.first
		end
	end

	def fetch_all
		@resources = Resource.all
		@devices = Device.all
		@set = res_set_find_specified_or_first
	end
end
