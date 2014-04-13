class AddLinesToTourPlanRoute < ActiveRecord::Migration
	def change
		add_column :tour_plan_routes, :public_line, :line_string, srid: 4326
		add_column :tour_plan_routes, :private_line, :line_string, srid: 4326
	end
end
