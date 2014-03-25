class TourResultController < ApplicationController
	def index
		@list = TourResult.all
	end

	def show
	end

	def create
		redirect_to(action: :index, :id => nil)
	end
end
