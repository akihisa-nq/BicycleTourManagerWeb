class ChangeElevationToZAxis < ActiveRecord::Migration
	def up
		if PrivateResultRoutes.count > 0
			change_column :private_result_routes, :path, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(path)"
		else
			change_column :private_result_routes, :path, "GEOMETRY(LineStringZ,4326)"
		end

		if PublicResultRoutes.count > 0
			change_column :public_result_routes, :path, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(path)"
		else
			change_column :public_result_routes, :path, "GEOMETRY(LineStringZ,4326)"
		end

		if TourPlanRoutes.count > 0
			change_column :tour_plan_routes, :public_line, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(public_line)"
			change_column :tour_plan_routes, :private_line, "GEOMETRY(LineStringZ,4326) USING ST_Force_3D(private_line)"
		else
			change_column :tour_plan_routes, :public_line, "GEOMETRY(LineStringZ,4326)"
			change_column :tour_plan_routes, :private_line, "GEOMETRY(LineStringZ,4326)"
		end

		if ResultPoints.count > 0
			change_column :result_points, :point, "GEOMETRY(PointZ,4326) USING ST_Force_3D(point)"
		else
			change_column :result_points, :point, "GEOMETRY(PointZ,4326)"
		end
		remove_column :result_points, :elevation

		if TourPlanPoints.count > 0
			change_column :tour_plan_points, :point, "GEOMETRY(PointZ,4326) USING ST_Force_3D(point)"
		else
			change_column :tour_plan_points, :point, "GEOMETRY(PointZ,4326)"
		end
		remove_column :tour_plan_points, :elevation
	end

	def down
		add_column :result_points, :elevation, :float
		if ResultPoints.count > 0
			change_column :result_points, :point, "GEOMETRY(LineString,4326) USING ST_Force_2D(point)"
		else
			change_column :result_points, :point, "GEOMETRY(LineString,4326)"
		end

		add_column :tour_plan_points, :elevation, :integer
		if TourPlanPoints.count > 0
			change_column :tour_plan_points, :point, "GEOMETRY(LineString,4326) USING ST_Force_2D(point)"
		else
			change_column :tour_plan_points, :point, "GEOMETRY(LineString,4326)"
		end

		if PrivateResultRoutes.count > 0
			change_column :private_result_routes, :path, "GEOMETRY(LineString,4326) USING ST_Force_2D(path)"
		else
			change_column :private_result_routes, :path, "GEOMETRY(LineString,4326)"
		end

		if PublicResultRoutes.count > 0
			change_column :public_result_routes, :path, "GEOMETRY(LineString,4326) USING ST_Force_2D(path)"
		else
			change_column :public_result_routes, :path, "GEOMETRY(LineString,4326)"
		end

		if TourPlanRoutes.count > 0
			change_column :tour_plan_routes, :public_line, "GEOMETRY(LineString,4326) USING ST_Force_2D(public_line)"
			change_column :tour_plan_routes, :private_line, "GEOMETRY(LineString,4326) USING ST_Force_2D(private_line)"
		else
			change_column :tour_plan_routes, :public_line, "GEOMETRY(LineString,4326)"
			change_column :tour_plan_routes, :private_line, "GEOMETRY(LineString,4326)"
		end
	end
end
