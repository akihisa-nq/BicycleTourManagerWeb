class AddPublishedToTourResult < ActiveRecord::Migration
	def change
		add_column :tour_results, :published, :bool
	end
end
