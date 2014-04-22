class AddDistanceToTourPlanPoint < ActiveRecord::Migration
	def change
		add_column :tour_plan_points, :distance, :integer
		add_column :tour_plan_points, :elevation, :integer
	end
end
