class Reset::Graph
	def self.regenerate_result
		::TourResult.find_each do |tour|
			tour.need_update_graph = true
			tour.save!
		end
	end

	def self.regenerate_plan
		::TourPlan.find_each do |plan|
			::TourPlan.generate(plan.id)
		end
	end
end
