class AddTimeToTourPlanPoint < ActiveRecord::Migration
	def change
		add_column :tour_plan_points, :target_time, :datetime
		add_column :tour_plan_points, :limit_time, :datetime
	end
end
