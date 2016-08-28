class ResultPoint < ActiveRecord::Base
end

class ChangeToLinestringAndArrayFromResultPoints < ActiveRecord::Migration
  def up
	add_column :public_result_routes, :speed, :float, array: true
	add_index  :public_result_routes, :speed, using: 'gin'
	add_column :public_result_routes, :time, :datetime, array: true
	add_index  :public_result_routes, :time, using: 'gin'

	PublicResultRoute.find_each(batch_size: 1) do |route|
		line_points = []
		route.time = []
		route.speed = []
		ResultPoint.where("public_result_route_id = ?", route.id).order("time").each do |pt|
			line_points << pt.point
			route.time << pt.time
			route.speed << pt.speed
		end
		route.path = BTM.factory.line_string(line_points)

		route.save!
	end

	add_column :private_result_routes, :speed, :float, array: true
	add_index  :private_result_routes, :speed, using: 'gin'
	add_column :private_result_routes, :time, :datetime, array: true
	add_index  :private_result_routes, :time, using: 'gin'

	PrivateResultRoute.find_each(batch_size: 1) do |route|
		line_points = []
		route.time = []
		route.speed = []
		ResultPoint.where("private_result_route_id = ?", route.id).order("time").each do |pt|
			line_points << pt.point
			route.time << pt.time
			route.speed << pt.speed
		end
		route.path = BTM.factory.line_string(line_points)
		route.save!
	end

	drop_table :result_points
  end

  def down
	create_table :result_points do |t|
      t.float    "speed"
      t.datetime "time"
      t.integer  "public_result_route_id"
      t.integer  "private_result_route_id"
      t.geometry "point",                   limit: {:srid=>4326, :type=>"point", :has_z=>true}
	end

	ResultPoint.delete_all

	PublicResultRoute.find_each(batch_size: 1) do |route|
		route.path.points.each.with_index do |pt, i|
			ResultPoint.create(
				public_result_route_id: route.id,
				time: route.time[i],
				speed: route.speed[i],
				point: pt
				)
		end
	end

    remove_index  :public_result_routes, :speed
	remove_column :public_result_routes, :speed
    remove_index  :public_result_routes, :time
	remove_column :public_result_routes, :time

	PrivateResultRoute.find_each(batch_size: 1) do |route|
		route.path.points.each.with_index do |pt, i|
			ResultPoint.create(
				private_result_route_id: route.id,
				time: route.time[i],
				speed: route.speed[i],
				point: pt
				)
		end
	end

    remove_index  :private_result_routes, :speed
	remove_column :private_result_routes, :speed
    remove_index  :private_result_routes, :time
	remove_column :private_result_routes, :time
  end
end
