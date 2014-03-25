class TourResultController < ApplicationController
	def index
		@list = TourResult.all
	end

	def show
		@tour_result = TourResult.find(params[:id])
		@title = "#{@tour_result.start_time.strftime("%Y/%m/%d")} #{@tour_result.name}"
		render layout: "tour_result_viewer"
	end

	def create
		attr = params[:tour_result].permit(:gpx_file)
		tour_result = TourResult.load(attr[:gpx_file])
		tour_result.save!

		redirect_to(action: :index, :id => nil)
	end

	def gpx_file
		@tour_result = TourResult.find(params[:id])

		headers["Content-Type"] = "application/xml; charset=UTF-8"
		render(:text => @tour_result.to_gpx(true), :layout => false)
	end
end
