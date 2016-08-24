class AddPositionToTourPlanUpHill < ActiveRecord::Migration
  def change
	  add_column :tour_plan_up_hills, :position, :integer
  end
end
