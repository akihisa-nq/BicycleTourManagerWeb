class ResourceEntry < ActiveRecord::Base
	belongs_to :resource

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, ResourceSet)
			ResourceEntry.where(["id = ?", id]).delete_all
		end
	end
end
