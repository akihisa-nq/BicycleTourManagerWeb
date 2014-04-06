class AddTimeZoneToTourResult < ActiveRecord::Migration
	def change
		add_column :tour_results, :time_zone, :string
	end
end
