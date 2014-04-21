class Resource < ActiveRecord::Base
	def self.destroy_with_auth(user, id)
		if user.can?(:delete, ResourceSet)
			Resource.where(["id = ?", id]).delete_all
		end
	end

	def self.create_with_auth(user, attr)
		if user.can?(:edit, ResourceSet)
			unless attr[:name].empty?
				Resource.create(attr)
			end
		end
	end

	def self.all_with_auth(user)
		if user.can?(:edit, ResourceSet)
			Resource.all
		end
	end

	def self.update_with_auth(user, id, attr)
		if user.can?(:edit, ResourceSet)
			Resource.where(["id = ?", id]).update_all(attr)
		end
	end
end
