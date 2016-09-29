class ResourceSet < ActiveRecord::Base
	has_many :resource_entries, dependent: :destroy
	has_many :device_entries, dependent: :destroy

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

	def self.update_with_auth(user, id, attr, res_entries, res_add, dev_entries, dev_add)
		if user.can?(:edit, ResourceSet)
			ResourceSet.where(["id = ?", id]).update_all(attr)

			res_entries.each do |id, attr|
				ResourceEntry.where(["id = ?", id]).update_all(attr)
			end

			unless res_add[:amount].empty? \
				&& res_add[:buffer].empty? \
				&& res_add[:recovery_interval].empty?
			then
				res_entry_new = ResourceEntry.new(res_add)
				res_entry_new.resource_set_id = id
				res_entry_new.save!
			end

			dev_entries.each do |id, attr|
				DeviceEntry.where(["id = ?", id]).update_all(attr)
			end

			unless dev_add[:purpose].empty?
				dev_entry_new = DeviceEntry.new(dev_add)
				dev_entry_new.resource_set_id = id
				dev_entry_new.save!
			end
		end
	end
end
