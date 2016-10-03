module Api
	class UserController < Api::BaseController
		def show
			if params[:id] == "current"
				render json: { email: current_user_or_guest.email }.to_json
			else
				render json: { email: nil }.to_json
			end
		end
	end
end
