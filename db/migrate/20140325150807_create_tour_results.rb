class CreateTourResults < ActiveRecord::Migration
	def change
		create_table :tour_results do |t|
			t.column :start_time, :datetime
			t.column :finish_time, :datetime
			t.column :name, :string
			t.timestamps
		end
	end
end
