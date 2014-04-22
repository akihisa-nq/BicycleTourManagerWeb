class AddTourPlanIdToTourResult < ActiveRecord::Migration
	def change
		add_column :tour_results, :tour_plan_id, :integer
	end
end
