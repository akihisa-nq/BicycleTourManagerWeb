class CreateTourPlanCaches < ActiveRecord::Migration
	def change
		create_table :tour_plan_caches do |t|
			t.text :request
			t.text :response
			t.point :point, :srid => 4326
		end
	end
end
