class Samples::Set
	def self.no_data
		::User.delete_all
		Samples::User.set_test_users

		::TourResult.delete_all
	end

	def self.tours
		::User.delete_all
		Samples::User.set_test_users

		::TourResult.delete_all
		Dir.glob(File.join(File.dirname(__FILE__), "gpx/*.gpx")) do |file|
			puts file
			TourResult.load(File.open(file, "r:utf-8")).save!
		end
	end
end
