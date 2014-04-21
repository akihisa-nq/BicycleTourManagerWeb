class AddConsumptionToDevice < ActiveRecord::Migration
	def change
		add_column :devices, :consumption, :integer
	end
end
