class CreateTourImages < ActiveRecord::Migration
	def change
		create_table :tour_images do |t|
			t.column :tour_result_id, :integer
			t.column :shot_on, :datetime
			t.column :text, :string
			t.timestamps
		end
	end
end
