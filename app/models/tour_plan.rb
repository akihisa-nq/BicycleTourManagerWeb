class TourPlan < ActiveRecord::Base
	has_many :tour_plan_routes

	def self.list_all(user, page)
		if user.can? :edit, TourPlan
			TourPlan.paginate(page: page, per_page: 10).order("created_at DESC")
		else
			TourPlan.paginate(page: page, per_page: 10).where("published = true").order("created_at DESC")
		end
	end

	def self.create_with_auth(user, name, url)
		if user.can? :edit, TourPlan
			plan = TourPlan.new(name: name)
			plan.tour_plan_routes.build(name: name)
			plan.tour_plan_routes[0].tour_plan_paths.build(google_map_url: url)
			plan.save!

			plan
		else
			nil
		end
	end
end
