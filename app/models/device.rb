class Device < ActiveRecord::Base
	has_one :resource

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, ResourceSet)
			Device.where(["id = ?", id]).delete_all
		end
	end

	def self.create_with_auth(user, attr)
		if user.can?(:edit, ResourceSet)
			unless attr[:name].empty? && attr[:resource_id].empty? && attr[:interval].empty?
				Device.create(attr)
			end
		end
	end

	def self.all_with_auth(user)
		if user.can?(:edit, ResourceSet)
			Device.all
		end
	end
end
