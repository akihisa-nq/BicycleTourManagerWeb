class CreateResourceEntries < ActiveRecord::Migration
	def change
		create_table :resource_entries do |t|
			t.integer :resource_set_id
			t.integer :resource_id
			t.integer :amount
			t.integer :buffer
			t.integer :recovery_interval
		end
	end
end
