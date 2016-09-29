class CreateTourGos < ActiveRecord::Migration
  def change
    create_table :tour_gos do |t|
	  t.integer :tour_plan_id
      t.column :start_time, :datetime
    end
  end
end
