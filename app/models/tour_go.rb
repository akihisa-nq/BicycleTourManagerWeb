class TourGo < ActiveRecord::Base
	has_many :tour_go_events, -> { order("occured_on ASC") }

	def self.all_with_auth(user, offset, limit)
		if user.can? :edit, TourGo
			TourGo.order("created_at DESC").offset(offset).limit(limit)
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
			TourGo.where(["id = ?", id]).delete_all
		end
	end

	def self.find_with_auth(user, id)
		go = nil
		if user.can? :edit, TourGo
			go = TourGo.find(id)
		end
		go
	end
end
