class CreateTourPlanUpHills < ActiveRecord::Migration
  def change
    create_table :tour_plan_up_hills do |t|
      t.geometry "point",              limit: {:srid=>4326, :type=>"point", :has_z=>true}
      t.integer  "distance"
      t.float    "length"
      t.integer  "tour_plan_point_id"
      t.float    "gradient"
      t.timestamps null: false
    end
  end
end
