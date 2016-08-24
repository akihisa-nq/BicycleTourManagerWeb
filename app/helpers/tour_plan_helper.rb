module TourPlanHelper
	def icon_name(point)
		if point.pass
			if point.peak_type.to_sym == :peak_max
				path_to_image("/peak.png")
			else
				path_to_image("/bottom.png")
			end
		else
			path_to_image("/mile_stone.png")
		end
	end

	def peak_type_text(point, route_index, index)
		case point.peak_type.to_sym
		when :peak_max
			"▲#{route_index}-#{index}"
		when :peak_min
			"▼#{route_index}-#{index}"
		else
			""
		end
	end
end
