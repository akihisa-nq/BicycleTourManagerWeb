class AddTimeZoneToTourPlan < ActiveRecord::Migration
	def change
		add_column :tour_plans, :time_zone, :string
		add_column :tour_plans, :start_time, :time
	end
end
