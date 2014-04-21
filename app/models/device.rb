class Device < ActiveRecord::Base
	belongs_to :resource

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, ResourceSet)
			Device.where(["id = ?", id]).delete_all
		end
	end

	def self.create_with_auth(user, attr)
		if user.can?(:edit, ResourceSet)
			unless attr[:name].empty? && attr[:interval].empty? && attr[:consumption].empty?
				Device.create(attr)
			end
		end
	end

	def self.all_with_auth(user)
		if user.can?(:edit, ResourceSet)
			Device.all
		end
	end

	def self.update_with_auth(user, id, attr)
		if user.can?(:edit, ResourceSet)
			Device.where(["id = ?", id]).update_all(attr)
		end
	end
end
