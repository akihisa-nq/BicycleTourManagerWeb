class AddResourceSetIdToTourPlan < ActiveRecord::Migration
	def change
		add_column :tour_plans, :resource_set_id, :integer
	end
end
