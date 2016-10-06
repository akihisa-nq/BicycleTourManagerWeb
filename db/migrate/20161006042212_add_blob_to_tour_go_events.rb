class AddBlobToTourGoEvents < ActiveRecord::Migration
  def change
	  add_column :tour_go_events, :blob, :binary
  end
end
