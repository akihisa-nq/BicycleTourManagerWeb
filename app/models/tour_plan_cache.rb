class TourPlanCache < ActiveRecord::Base
	def self.cache(key, &value)
		data = nil

		cache = TourPlanCache.where(["request = ?", key]).first
		if cache.nil?
			data = value.call

			cache = TourPlanCache.new
			if data.responed_to?(:x)
				cache.point = data
			else
				cache.response = data
			end

			cache.save
		end

		if cache.point
			cache.point
		else
			cache.response
		end
	end
end
