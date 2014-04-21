class DeviceEntry < ActiveRecord::Base
	belongs_to :device

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, ResourceSet)
			DeviceEntry.where(["id = ?", id]).delete_all
		end
	end
end
