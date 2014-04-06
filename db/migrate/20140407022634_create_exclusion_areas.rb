class CreateExclusionAreas < ActiveRecord::Migration
	def change
		create_table :exclusion_areas do |t|
			t.point :point, :srid => 4326
			t.float :distance
		end
	end
end
