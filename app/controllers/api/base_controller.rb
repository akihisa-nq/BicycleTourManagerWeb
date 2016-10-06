class Api::BaseController < ActionController::Base
	include CanCan::ControllerAdditions

	clear_respond_to
	respond_to :json

	before_action :authenticate_user

	# check_authorization unless: :devise_controller?

	rescue_from CanCan::AccessDenied do |e|
		render json: errors_json(e.message), status: :forbidden
	end

	rescue_from ActiveRecord::RecordNotFound do |e|
		render json: errors_json(e.message), status: :not_found
	end

	private

	def authenticate_user
		if doorkeeper_token
			Thread.current[:current_user] = User.find(doorkeeper_token.resource_owner_id)
		end
	end

	def current_user_or_guest
		Thread.current[:current_user] || current_user || User.new
	end

	def errors_json(messages)
		{ errors: [*messages] }
	end
end


