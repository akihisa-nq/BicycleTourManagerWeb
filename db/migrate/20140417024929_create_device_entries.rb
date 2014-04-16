class CreateDeviceEntries < ActiveRecord::Migration
	def change
		create_table :device_entries do |t|
			t.integer :resource_set_id
			t.integer :device_id
			t.string :purpose
		end
	end
end
