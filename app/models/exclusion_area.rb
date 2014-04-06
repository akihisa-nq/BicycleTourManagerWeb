class ExclusionArea < ActiveRecord::Base
	validates :point, presence: true
	validates :distance, presence: true

	set_rgeo_factory_for_column(:point, RGeo::Geographic.spherical_factory(:srid => 4326))

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
			area.point = rgeo_factory_for_column(:point).point(attr[:lon], attr[:lat])
			area.distance = attr[:distance]
			area.save
			area
		end
	end

	def self.update_with_auth(user, id, attr)
		if user.can?(:edit, ExclusionArea)
			area = ExclusionArea.find(id)
			area.point = rgeo_factory_for_column(:point).point(attr[:lon], attr[:lat])
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
