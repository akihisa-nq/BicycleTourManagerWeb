class ExclusionArea < ActiveRecord::Base
	validates :point, presence: true
	validates :distance, presence: true

	attribute :point, :point

	def self.all_with_auth(user)
		if user.can?(:edit, ExclusionArea)
			ExclusionArea.all
		else
			[]
		end
	end

	def self.create_with_auth(user, attr)
		if user.can?(:edit, ExclusionArea)
			area = ExclusionArea.new
			area.point = BTM.factory.point(attr[:lon], attr[:lat])
			area.distance = attr[:distance]
			area.save
			area
		end
	end

	def self.update_with_auth(user, id, attr)
		if user.can?(:edit, ExclusionArea)
			area = ExclusionArea.find(id)
			area.point = BTM.factory.point(attr[:lon], attr[:lat])
			area.distance = attr[:distance]
			area.save
		else
			false
		end
	end

	def self.destroy_with_auth(user, id)
		if user.can?(:edit, ExclusionArea)
			delete(id)
		end
	end
end
