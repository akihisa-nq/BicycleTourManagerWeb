class CreateDevices < ActiveRecord::Migration
	def change
		create_table :devices do |t|
			t.string :name
			t.integer :resource_id
			t.integer :interval
		end
	end
end
