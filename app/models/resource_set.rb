class ResourceSet < ActiveRecord::Base
	has_many :resource_entries
	has_many :device_entries
end
