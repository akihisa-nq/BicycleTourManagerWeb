class AddStartTimeToDeviceEntry < ActiveRecord::Migration
	def change
		add_column :device_entries, :start_time, :time
	end
end
