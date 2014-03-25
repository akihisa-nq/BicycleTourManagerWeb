class PrivateResultRoute < ActiveRecord::Base
	belongs_to :tour_result
	acts_as_list scope: :tour_result

	has_many :result_points
end
