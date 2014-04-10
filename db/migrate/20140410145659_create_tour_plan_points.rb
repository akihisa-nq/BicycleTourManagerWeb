class CreateTourPlanPoints < ActiveRecord::Migration
	def change
		create_table :tour_plan_points do |t|
			t.integer :tour_route_id
			t.point :point, :srid => 4326
			t.string :name
			t.string :comment
			t.string :direction
			t.float :rest_time
			t.float :target_speed
			t.float :limit_speed
			t.integer :position
		end
	end
end
