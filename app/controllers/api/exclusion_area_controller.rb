module Api
	class ExclusionAreaController < Api::BaseController
		def list
			exclusion_areas = ExclusionArea.all_with_auth(current_user_or_guest)
			render json: { exclusion_areas: exclusion_areas }.to_json
		end
	end
end
