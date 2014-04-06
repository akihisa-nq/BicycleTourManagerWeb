# coding: utf-8

require 'spec_helper'

require "stringio"

describe TourResult do
	it "load gpx stream" do
		path = File.join(File.dirname(__FILE__), "track.gpx")
		expect(File.exist?(path)).to eq true

		t = TourResult.load(File.open(path, "r:utf-8"))
		expect(t.name).to eq "シクロ ジャンブル"
		expect(t.start_time).to eq Time.parse("2013-05-20T03:40:54Z")
		expect(t.finish_time).to eq Time.parse("2013-05-19T07:05:46Z")

		expect(t.public_result_routes.length).to eq 2
		expect(t.private_result_routes.length).to eq 2

		expect(t.public_result_routes[0].result_points.length).to be > 100
		expect(t.private_result_routes[0].result_points.length).to be > 100

		t.save!
	end

	context "guest user" do
		it "cannot load and save" do
			path = File.join(File.dirname(__FILE__), "track.gpx")
			expect(File.exist?(path)).to eq true

			user = User.new(email: "test@test.com", password: "testtest")
			user.role = nil
			expect(TourResult.load_and_save(user, File.open(path, "r:utf-8"), "Tokyo")).to eq nil
		end

		it "cannot add images" do
			tour = TourResult.create

			image = File.join(File.dirname(__FILE__), "image.jpg")
			images = [ StringIO.new(File.open(image, "rb") {|f| f.read })]

			user = User.new(email: "test@test.com", password: "testtest")
			user.role = nil
			TourResult.add_images(user, tour.id, images)
			expect(tour.tour_images.length).to eq 0
		end
	end

	context "manager" do
		it "cannot load and save" do
			path = File.join(File.dirname(__FILE__), "track.gpx")
			expect(File.exist?(path)).to eq true

			user = User.new(email: "test@test.com", password: "testtest")
			user.role = "manager"
			expect(TourResult.load_and_save(user, File.open(path, "r:utf-8"), "Tokyo")).to eq nil
		end

		it "cannot add images" do
			tour = TourResult.create

			image = File.join(File.dirname(__FILE__), "image.jpg")
			images = [ StringIO.new(File.open(image, "rb") {|f| f.read })]

			user = User.new(email: "test@test.com", password: "testtest")
			user.role = "manager"
			TourResult.add_images(user, tour.id, images)
			expect(tour.tour_images.length).to eq 0
		end
	end

	context "editor" do
		it "can load and save" do
			path = File.join(File.dirname(__FILE__), "track.gpx")
			expect(File.exist?(path)).to eq true

			user = User.new(email: "test@test.com", password: "testtest")
			user.role = "editor"
			expect(TourResult.load_and_save(user, File.open(path, "r:utf-8"), "Tokyo")).not_to eq nil
		end

		it "can add images" do
			tour = TourResult.create

			image = File.join(File.dirname(__FILE__), "image.jpg")
			images = [ StringIO.new(File.open(image, "rb") {|f| f.read })]

			user = User.new(email: "test@test.com", password: "testtest")
			user.role = "editor"
			TourResult.add_images(user, tour.id, images)
			expect(tour.tour_images.length).to eq 1
		end
	end

	# FIXME: need test for loading images
end
