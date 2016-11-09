class AddPublicColumnToTourPlanTiles < ActiveRecord::Migration[5.0]
  def up
	remove_index(:tour_plan_tiles, [:x, :y, :zoom])
	add_column(:tour_plan_tiles, :public, :boolean, null: false)
	add_index(:tour_plan_tiles, [:x, :y, :zoom, :public])
  end

  def down
	remove_index(:tour_plan_tiles, [:x, :y, :zoom, :public])
	remove_column(:tour_plan_tiles, :public)
	add_index(:tour_plan_tiles, [:x, :y, :zoom])
  end
end
