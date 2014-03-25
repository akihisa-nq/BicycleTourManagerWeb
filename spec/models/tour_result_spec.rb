# coding: utf-8

require 'spec_helper'

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
end
