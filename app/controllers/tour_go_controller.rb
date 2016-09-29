class TourGoController < ApplicationController
	before_action :authenticate_user!

	def index
		@tour_gos = TourGo.list_all(current_user_or_guest, params[:page])
	end

	def destroy
		TourGo.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to( action: :index, page: params[:page] )
	end
end
