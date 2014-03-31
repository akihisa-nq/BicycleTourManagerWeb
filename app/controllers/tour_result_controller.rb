class TourResultController < ApplicationController
	before_action :authenticate_user!, only: [
		:create, :destroy,
		:create_images, :destroy_image,
	]

	def index
		@list = TourResult.all.order("start_time DESC")
	end

	def show
		@tour_result = TourResult.find(params[:id])
		@title = "#{@tour_result.start_time.strftime("%Y/%m/%d")} #{@tour_result.name}"
		render layout: "tour_result_viewer"
	end

	def create
		attr = params[:tour_result].permit(:gpx_file)
		TourResult.load_and_save(current_user, attr[:gpx_file])
		redirect_to(action: :index, :id => nil)
	end

	def destroy
		TourResult.destroy_with_auth(current_user, params[:id])
		redirect_to(action: :index, :id => nil)
	end

	def gpx_file
		@tour_result = TourResult.find(params[:id])

		headers["Content-Type"] = "application/xml; charset=UTF-8"
		render(:text => @tour_result.to_gpx(true, :route), :layout => false)
	end

	def create_images
		TourResult.add_images(current_user, params[:id], params[:tour_result][:images])
		redirect_to(action: :show, :id => params[:id])
	end

	def destroy_image
		TourImage.destroy_with_auth(current_user, params[:image_id])
		redirect_to(action: :show, :id => params[:id])
	end
end
