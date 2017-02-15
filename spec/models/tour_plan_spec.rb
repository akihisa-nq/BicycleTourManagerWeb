require 'rails_helper'

RSpec.describe TourPlan, type: :model do
	it "can generate map tiles" do
		user = User.new(email: "test@test.com", password: "testtest")
		user.role = "editor"

		url = "https://www.google.co.jp/maps/dir/35.0760873,135.5422839/35.0712642,135.3410039/34.8917131,135.4095239/34.9794159,135.7520114/@34.9436824,135.6366549,12z/data=!4m6!4m5!1m0!1m0!1m0!1m0!3e2?hl=ja"
		plan1 = TourPlan.create_with_auth(
			user,
			{
				name: "Test",
				time_zone: "Tokyo",
				start_time: Time.now
			},
			{
				google_map_url: url
			})
		expect(plan1).to_not be_nil
		plan1.generate_tiles(false, 6, 6)

		plan2 = TourPlan.create_with_auth(
			user,
			{
				name: "Test2",
				time_zone: "Tokyo",
				start_time: Time.now
			},
			{
				google_map_url: url
			})
		expect(plan2).to_not be_nil

		plan2.generate_tiles(true, 6, 6)
	end
end
