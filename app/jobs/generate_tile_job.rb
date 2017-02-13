class GenerateTileJob < ApplicationJob
	queue_as :default

	def perform(*args)
		begin
			kind = args[0].to_sym
			id = args[1]

			if kind == :tour_plan
				plan = TourPlan.find(id)
				plan.generate_tiles(true, 6, 14)
			else
				result = TourResult.find(id)
				# FIXME
			end
		rescue => e
			Rails.logger.fatal(e.message)
			Rails.logger.fatal(e.backtrace.join("\n"))
		end
	end
end
