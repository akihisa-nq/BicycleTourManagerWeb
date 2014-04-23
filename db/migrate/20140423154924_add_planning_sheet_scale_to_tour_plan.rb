class AddPlanningSheetScaleToTourPlan < ActiveRecord::Migration
	def change
		add_column :tour_plans, :planning_sheet_scale, :float
	end
end
