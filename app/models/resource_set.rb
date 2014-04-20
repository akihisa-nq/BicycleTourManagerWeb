class ResourceSet < ActiveRecord::Base
	has_many :resource_entries
	has_many :device_entries

	def self.create_with_auth(user, attr)
		if user.can?(:edit, ResourceSet)
			ResourceSet.create(attr)
		end
	end

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, ResourceSet)
			ResourceSet.where(["id = ?", id]).delete_all
		end
	end

	def self.edit_with_auth(user, id)
		if user.can?(:edit, ResourceSet)
			ResourceSet.find(id)
		end
	end

	def self.first_with_auth(user)
		if user.can?(:edit, ResourceSet)
			ResourceSet.first
		end
	end

	def self.all_with_auth(user)
		if user.can?(:edit, ResourceSet)
			ResourceSet.all
		end
	end
end
