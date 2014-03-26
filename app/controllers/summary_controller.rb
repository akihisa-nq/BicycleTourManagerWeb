class SummaryController < ApplicationController
	before_action :authenticate_user!, only: [ :edit_user ]

	def index
	end

	def login
		@users = User.all
	end

	def edit_user
		if can? :manage, User
			params[:user].each do |id, attr|
				User.find(id).update(attr)
			end
		end

		redirect_to(action: :login)
	end
end
