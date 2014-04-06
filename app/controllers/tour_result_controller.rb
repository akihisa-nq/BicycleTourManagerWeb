class TourResultController < ApplicationController
	before_action :authenticate_user!, only: [
		:create, :destroy, :toggle_visible,
		:create_images, :destroy_image,
		:update_image_text
	]

	def index
		@list = TourResult.list_all(current_user_or_guest, params[:page])
	end

	def show
		@tour_result = TourResult.find_with_auth(current_user_or_guest, params[:id])
		@title = "#{@tour_result.start_time.strftime("%Y/%m/%d")} #{@tour_result.name}"
		render layout: "tour_result_viewer"
	end

	def create
		attr = params[:tour_result].permit(:gpx_file, :time_zone)
		ret = TourResult.load_and_save(current_user_or_guest, attr[:gpx_file])
		if ret
			redirect_to(action: :index, id: nil, page: TourResult.page_for(current_user_or_guest, ret.id))
		else
			redirect_to(action: :index, id: nil, page: params[:page])
		end
	end

	def destroy
		page = TourResult.page_for(current_user_or_guest, params[:id])
		TourResult.destroy_with_auth(current_user_or_guest, params[:id])
		redirect_to(action: :index, id: nil, page: page)
	end

	def toggle_visible
		TourResult.toggle_visible(current_user_or_guest, params[:id])
		redirect_to(action: :index, id: nil, page: TourResult.page_for(current_user_or_guest, params[:id]))
	end

	def gpx_file
		@tour_result = TourResult.find_with_auth(current_user_or_guest, params[:id])

		headers["Content-Type"] = "application/xml; charset=UTF-8"
		render(:text => @tour_result.to_gpx(true, :route), :layout => false)
	end

	def create_images
		TourResult.add_images(current_user_or_guest, params[:id], params[:tour_result][:images])
		redirect_to(action: :show, :id => params[:id])
	end

	def destroy_image
		TourImage.destroy_with_auth(current_user_or_guest, params[:image_id])
		redirect_to(action: :show, :id => params[:id])
	end

	def update_image_text
		attr = params[:img].permit(:text)
		TourImage.update_text(current_user_or_guest, params[:id], attr[:text])
		@id = params[:id]
		@text = attr[:text]
		@index = params[:index]
		headers["Content-Type"] = "text/javascript"
		render(partial: "update_image_text")
	end

	private

	def current_user_or_guest
		current_user || User.new
	end
end
