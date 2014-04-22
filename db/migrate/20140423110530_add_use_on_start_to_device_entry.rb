class AddUseOnStartToDeviceEntry < ActiveRecord::Migration
	def change
		add_column :device_entries, :use_on_start, :boolean
	end
end
