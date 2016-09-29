class CreateTourGoEvents < ActiveRecord::Migration
  def change
    create_table :tour_go_events do |t|
	  t.integer :tour_go_id
      t.column :occured_on, :datetime
	  t.integer :event_type, default: 0, null: false, limit: 1
	  t.integer :tour_plan_point_id
    end
  end
end
