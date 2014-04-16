class CreateResourceSets < ActiveRecord::Migration
	def change
		create_table :resource_sets do |t|
			t.string :name
		end
	end
end
