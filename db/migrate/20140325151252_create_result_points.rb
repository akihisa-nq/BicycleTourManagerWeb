class CreateResultPoints < ActiveRecord::Migration
	def change
		create_table :result_points do |t|
			t.point :point, :srid => 4326
			t.column :elevation, :float
			t.column :speed, :float
			t.column :time, :datetime
			t.column :public_result_route_id, :integer
			t.column :private_result_route_id, :integer
		end
	end
end
