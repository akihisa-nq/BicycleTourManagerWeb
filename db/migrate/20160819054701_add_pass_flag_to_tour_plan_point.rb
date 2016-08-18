class AddPassFlagToTourPlanPoint < ActiveRecord::Migration
  def change
    add_column :tour_plan_points, :pass, :boolean
  end
end
