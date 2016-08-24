class ChangeElevationToZAxis < ActiveRecord::Migration
	def up
		change_column :private_result_routes, :path, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(path)"
		change_column :public_result_routes, :path, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(path)"
		change_column :tour_plan_routes, :public_line, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(public_line)"
		change_column :tour_plan_routes, :private_line, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(private_line)"

		change_column :result_points, :point, "GEOMETRY(PointZ,4326) USING ST_Force_3D(point)"
		remove_column :result_points, :elevation

		change_column :tour_plan_points, :point, "GEOMETRY(PointZ,4326) USING ST_Force_3D(point)"
		remove_column :tour_plan_points, :elevation
	end

	def down
		add_column :result_points, :elevation, :float
		change_column :result_points, :point, "GEOMETRY(LineString,4326) USING ST_Force_2D(point)"

		add_column :tour_plan_points, :elevation, :integer
		change_column :tour_plan_points, :point, "GEOMETRY(LineString,4326) USING ST_Force_2D(point)"

		change_column :private_result_routes, :path, "GEOMETRY(LineString,4326) USING ST_Force_2D(path)"
		change_column :public_result_routes, :path, "GEOMETRY(LineString,4326) USING ST_Force_2D(path)"
		change_column :tour_plan_routes, :public_line, "GEOMETRY(LineString,4326) USING ST_Force_2D(public_line)"
		change_column :tour_plan_routes, :private_line, "GEOMETRY(LineString,4326) USING ST_Force_2D(private_line)"
	end
end
