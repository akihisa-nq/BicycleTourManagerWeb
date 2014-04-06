class Samples::Set
	def self.no_data
		::User.delete_all
		Samples::User.set_test_users

		::TourResult.delete_all
	end

	def self.tours
		::User.delete_all
		Samples::User.set_test_users

		::ExclusionArea.delete_all
		area = ::ExclusionArea.new
		area.point = ::ExclusionArea.rgeo_factory_for_column(:point).point(135.746702, 34.979099)
		area.distance = 20.0
		area.save!

		::TourResult.delete_all
		::TourImage.delete_all

		Dir.glob(File.join(File.dirname(__FILE__), "gpx/*.gpx")) do |file|
			puts file
			tour = ::TourResult.load(File.open(file, "r:utf-8"), "Tokyo")

			if File.basename(file) == "track_9.gpx"
				Dir.glob(File.join(File.dirname(__FILE__), "images/*.JPG")) do |img|
					tour.tour_images.build(image_data: File.open(img, "rb"))
				end
			end

			tour.save!
		end
	end
end
