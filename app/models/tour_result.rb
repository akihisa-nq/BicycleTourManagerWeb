# coding: utf-8

require "bicycle_tour_manager"

class TourResult < ActiveRecord::Base
	has_many :public_result_routes, -> { order("position ASC") }
	has_many :private_result_routes, -> { order("position ASC") }

	def self.load(stream)
		tour = BTM::GpxStream.read_from_stream(stream)

		tour_result = TourResult.new
		tour_result.name = tour.name
		tour_result.start_time = tour.start_date.getlocal
		tour_result.finish_time = tour.routes[-1].path_list[-1].steps[-1].time.getlocal

		tour.routes.each do |r|
			r.path_list.each do |p|
				line = BTM.factory.line_string(p.steps.map {|s| s.point_geos })

				# 公開
				pub_route = tour_result.public_result_routes.build
				pub_route.start_time = p.steps[0].time.getlocal
				pub_route.finish_time = p.steps[-1].time.getlocal
				pub_route.path = line

				# 非公開
				pri_route = tour_result.private_result_routes.build
				pri_route.start_time = p.steps[0].time.getlocal
				pri_route.finish_time = p.steps[-1].time.getlocal
				pri_route.path = line

				p.steps.each do |s|
					pt = ResultPoint.new
					pt.point = s.point_geos
					pt.elevation = s.ele
					pt.time = s.time.getlocal

					pub_route.result_points << pt
					pri_route.result_points << pt
				end
			end
		end

		tour_result
	end
end
