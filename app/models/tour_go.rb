class TourGo < ActiveRecord::Base
	has_many :tour_go_events, -> { order("occured_on ASC") }, dependent: :destroy
	belongs_to :tour_plan

	PER_PAGE = 10

	def self.all_with_auth(user, offset, limit)
		if user.can? :edit, TourGo
			TourGo
				.order("start_time DESC")
				.offset(offset)
				.limit(limit)
		else
			TourGo
				.joins(:tour_plan)
				.where(tour_plans: { published: true })
				.order("start_time DESC")
				.offset(offset)
				.limit(limit)
		end
	end

	def self.count_with_auth(user)
		if user.can? :edit, TourGo
			TourGo.count
		else
			TourGo
				.joins(:tour_plan)
				.where(tour_plans: { published: true })
				.count
		end
	end

	def self.new_with_auth(user, attr_go)
		if user.can? :edit, TourGo
			TourGo.new(attr_go)
		else
			nil
		end
	end

	def self.create_with_auth(user, attr_go)
		if user.can? :edit, TourGo
			go = TourGo.new(attr_go)
			go.save!
			go
		else
			nil
		end
	end

	def self.destroy_with_auth(user, id)
		if user.can?(:edit, TourGo)
			destroy([id])
		end
	end

	def self.find_with_auth(user, id)
		go = nil
		if user.can? :edit, TourGo
			go = TourGo.find(id)
		end
		go
	end

	def self.list_all(user, page)
		if user.can? :edit, TourGo
			TourGo
				.paginate(page: page, per_page: PER_PAGE)
				.order("start_time DESC")
		else
			TourGo
				.joins(:tour_plan)
				.where(tour_plans: { published: true })
				.paginate(page: page, per_page: PER_PAGE)
				.order("start_time DESC")
		end
	end

	def self.page_for(user, id)
		go = find_with_auth(user, id)
		if go
			count = 0
			if user.can? :edit, TourGo
				count = TourGo
					.where(["start_time >= ?", go.start_time])
					.count
			else
				count = TourGo
					.joins(:tour_plan)
					.where(tour_plans: { published: true })
					.where(["start_time >= ?", go.start_time])
					.count
			end
			(count - 1) / PER_PAGE + 1
		else
			1
		end
	end
end
