class CreatePublicResultRoutes < ActiveRecord::Migration
	def change
		create_table :public_result_routes do |t|
			t.column :tour_result_id, :integer
			t.column :position, :integer
			t.column :start_time, :datetime
			t.column :finish_time, :datetime
			t.column :name, :string
			t.line_string :path, :srid => 4326
			t.timestamps
		end
	end
end
