class TourPlanRoute < ActiveRecord::Base
	belongs_to :tour_plan
	acts_as_list scope: :tour_plan

	has_many :tour_plan_points, -> { order("position ASC") }
	has_many :tour_plan_paths, -> { order("position ASC") }

	def set_point_lines
		parser = RGeo::WKRep::WKBParser.new(private_line.factory, support_ewkb: true, support_wkb12: true)
		connection = ActiveRecord::Base.connection

		length = connection.select_one("SELECT ST_Length(Geography(private_line)) AS length FROM tour_plan_routes WHERE id = #{self.id}")["length"].to_f / 1000.0
		unit = 1.0 / length

		tour_plan_points.each do |pt|
			base = (pt.distance - tour_plan_points.first.distance).to_f / length

			start = base - unit * 0.5
			start = 0.0 if start < 0

			finish = base + unit * 0.5
			finish = 1.0 if finish > 1.0

			pt.near_line = parser.parse(connection.select_one("SELECT ST_LineSubstring(private_line, #{start}, #{finish}) AS line FROM tour_plan_routes WHERE id = #{self.id}")["line"])
		end

		nil
	end
end
