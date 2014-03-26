# coding: utf-8

require "bicycle_tour_manager"
require "stringio"

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
				pub_route = tour_result.public_result_routes.build
				pri_route = tour_result.private_result_routes.build

				logger.debug("check peak")
				p.check_peak
				p.check_distance_from_start

				logger.debug("check steps")
				line_points = []
				prev_line = p.steps.first
				prev_pt = p.steps.first

				p.steps.each do |s|
					add_line = false
					add_point = false

					if s.min_max != nil
						add_line = true
						add_point = true
					else
						add_line = (prev_line.distance_on_path(s) > 0.05)
						add_point = (prev_pt.distance_on_path(s) > 0.15)
					end

					if add_line
						line_points << s.point_geos
						prev_line = s
					end

					if add_point
						pt = ResultPoint.new
						pt.point = s.point_geos
						pt.elevation = s.ele
						pt.time = s.time.getlocal

						pub_route.result_points << pt
						pri_route.result_points << pt

						prev_pt = s
					end
				end

				line = BTM.factory.line_string(line_points)

				# 公開
				pub_route.start_time = p.steps[0].time.getlocal
				pub_route.finish_time = p.steps[-1].time.getlocal
				pub_route.path = line

				# 非公開
				pri_route.start_time = p.steps[0].time.getlocal
				pri_route.finish_time = p.steps[-1].time.getlocal
				pri_route.path = line
			end
		end

		tour_result
	end

	def to_tour(is_public_data, kind)
		tour = BTM::Tour.new
		tour.start_date = self.start_time
		tour.name = self.name

		list = []
		if is_public_data
			list = self.public_result_routes
		else
			list = self.private_result_routes
		end

		list.each do |r|
			tour.routes << BTM::Route.new
			tour.routes.last.path_list << BTM::Path.new

			case kind
			when :route
				r.path.points.each do |p|
					pt = BTM::Point.new(p.y, p.x)
					tour.routes.last.path_list.last.steps << pt
				end

			when :graph
				r.result_points.each do |p|
					pt = BTM::Point.new(p.point.y, p.point.x, p.elevation)
					pt.time = p.time
					tour.routes.last.path_list.last.steps << pt
				end
			end
		end

		tour.set_start_end
		tour
	end

	def to_gpx(is_public_data, kind)
		tour = self.to_tour(is_public_data, kind)
		io = StringIO.new("", "w")
		BTM::GpxStream.write_routes_to_stream(io, tour)
		io.string
	end
end
