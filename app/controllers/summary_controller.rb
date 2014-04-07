class SummaryController < ApplicationController
	before_action :authenticate_user!, only: [
		:edit_user,
		:management,
		:create_exclusion_area, :destroy_exclusion_area, :update_exclusion_area
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
end
