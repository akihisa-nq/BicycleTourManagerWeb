class CreateTourPlans < ActiveRecord::Migration
	def change
		create_table :tour_plans do |t|
			t.string :name
			t.boolean :published
			t.timestamps
		end
	end
end
