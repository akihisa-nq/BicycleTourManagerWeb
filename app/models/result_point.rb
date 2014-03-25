class ResultPoint < ActiveRecord::Base
	belongs_to :public_result_route
	belongs_to :private_result_result
end
