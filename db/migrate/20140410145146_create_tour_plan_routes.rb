class CreateTourPlanRoutes < ActiveRecord::Migration
	def change
		create_table :tour_plan_routes do |t|
			t.integer :tour_plan_id
			t.string :name
			t.integer :position
		end
	end
end
