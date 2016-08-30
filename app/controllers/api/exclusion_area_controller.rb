module Api
	class ExclusionAreaController < Api::BaseController
		def list
			render json: { name: "hoge" }
		end
	end
end
