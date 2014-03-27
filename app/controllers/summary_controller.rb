class SummaryController < ApplicationController
	before_action :authenticate_user!, only: [ :edit_user ]

	def index
	end

	def login
		@users = User.all
	end

	def edit_user
		User.update_role(current_user, params[:user])
		redirect_to(action: :login)
	end
end
