class AddElevationToTourPlan < ActiveRecord::Migration
	def change
		add_column :tour_plans, :elevation, :integer
	end
end
