class AddPeakTypeToTourPlanPoints < ActiveRecord::Migration
  def change
    add_column :tour_plan_points, :peak_type, :integer, default: 0, null: false, limit: 2
  end
end
