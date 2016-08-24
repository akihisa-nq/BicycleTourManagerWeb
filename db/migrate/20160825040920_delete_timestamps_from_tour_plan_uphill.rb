class DeleteTimestampsFromTourPlanUphill < ActiveRecord::Migration
  def up
	  remove_column :tour_plan_up_hills, :updated_at
	  remove_column :tour_plan_up_hills, :created_at
  end

  def down
	  add_column :tour_plan_up_hills, :created_at, :datetime, null: false
	  add_column :tour_plan_up_hills, :updated_at, :datetime, null: false
  end
end
