class Api::BaseController < ActionController::Base
	include CanCan::ControllerAdditions

	clear_respond_to
	respond_to :json

	rescue_from CanCan::AccessDenied do |e|
		render json: errors_json(e.message), status: :forbidden
	end

	rescue_from ActiveRecord::RecordNotFound do |e|
		render json: errors_json(e.message), status: :not_found
	end

	private

	def current_user_or_guest
		Thread.current[:current_user] || current_user || User.new
	end

	def errors_json(messages)
		{ errors: [*messages] }
	end
end


