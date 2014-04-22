class AddElevationToTourResult < ActiveRecord::Migration
	def change
		add_column :tour_results, :elevation, :integer
	end
end
