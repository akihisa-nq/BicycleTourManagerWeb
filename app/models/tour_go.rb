class TourGo < ActiveRecord::Base
	has_many :tour_go_events, -> { order("occured_on ASC") }, dependent: :destroy
	belongs_to :tour_plan

	PER_PAGE = 10

	def self.all_with_auth(user, offset, limit)
		if user.can? :edit, TourGo
			TourGo.order("start_time DESC").offset(offset).limit(limit)
		else
			[]
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
			TourGo.paginate(page: page, per_page: PER_PAGE).order("start_time DESC")
		else
			[]
		end
	end

	def self.page_for(user, id)
		go = find_with_auth(user, id)
		if go
			(TourPlan.where(["start_time >= ?", go.start_time]).count - 1) / PER_PAGE + 1
		else
			1
		end
	end
end
