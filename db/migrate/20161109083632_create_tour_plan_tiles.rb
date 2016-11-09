class CreateTourPlanTiles < ActiveRecord::Migration[5.0]
  def change
    create_table :tour_plan_tiles do |t|
	  t.integer :x, null: false
	  t.integer :y, null: false
	  t.integer :zoom, null: false
	  t.binary :image, null: false
      t.index([:x, :y, :zoom])
    end
  end
end
