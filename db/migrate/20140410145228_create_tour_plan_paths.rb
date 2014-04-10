class CreateTourPlanPaths < ActiveRecord::Migration
	def change
		create_table :tour_plan_paths do |t|
			t.integer :tour_plan_route_id
			t.string :google_map_url
			t.integer :position
		end
	end
end
