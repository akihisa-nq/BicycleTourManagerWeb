class TourPlanPoint < ActiveRecord::Base
	belongs_to :tour_plan_route
	acts_as_list scope: :tour_plan_route

	def lon
		point.x
	end

	def lat
		point.y
	end

	def self.destroy_with_auth(user, id)
		if user.can?(:delete, TourPlan)
			TourPlanPoint.delete_all(["id = ?", id])
		end
	end

	def road_nw; parse_direction; @road["nw"]; end
	def road_n; parse_direction; @road["n"]; end
	def road_ne; parse_direction; @road["ne"]; end
	def road_w; parse_direction; @road["w"]; end
	def road_e; parse_direction; @road["e"]; end
	def road_sw; parse_direction; @road["sw"]; end
	def road_s; parse_direction; @road["s"]; end
	def road_se; parse_direction; @road["se"]; end
	def dir_src; parse_direction; @dir_src; end
	def dir_dest; parse_direction; @dir_dest; end
	def road; parse_direction; @road; end

	def self.pack_direction(attr)
		dir = []
		dir << "nw:#{attr[:road_nw]}" unless attr[:road_nw].empty?
		dir << "n:#{attr[:road_n]}" unless attr[:road_n].empty?
		dir << "ne:#{attr[:road_ne]}" unless attr[:road_ne].empty?
		dir << "w:#{attr[:road_w]}" unless attr[:road_w].empty?
		dir << "e:#{attr[:road_e]}" unless attr[:road_e].empty?
		dir << "sw:#{attr[:road_sw]}" unless attr[:road_sw].empty?
		dir << "s:#{attr[:road_s]}" unless attr[:road_s].empty?
		dir << "se:#{attr[:road_se]}" unless attr[:road_se].empty?
		dir = dir.join(",")

		attr.delete(:road_nw)
		attr.delete(:road_n)
		attr.delete(:road_ne)
		attr.delete(:road_w)
		attr.delete(:road_e)
		attr.delete(:road_sw)
		attr.delete(:road_s)
		attr.delete(:road_se)

		dir += "|"

		dir += "#{attr[:dir_src]} > #{attr[:dir_dest]}"

		attr.delete(:dir_src)
		attr.delete(:dir_dest)

		attr[:direction] = dir
	end

	def exclude?
		@exclude unless @exclude.nil?

		ExclusionArea.all.each do |area|
			pt1 = BTM::Point.new(point.y, point.x)
			pt2 = BTM::Point.new(area.point.y, area.point.x)

			if pt1.distance(pt2) < area.distance
				@exclude = true
				return true
			end
		end

		@exclude = false
		return false
	end

	attr_accessor :tmp_info

	private

	def parse_direction
		unless @parsed
			@road = {}

			if direction
				dirs = direction.split("|").map {|s| s.strip }

				if dirs[0] && ! dirs[0].empty?
					@road = Hash[*dirs[0].split(/[:,]/).map{|i| i.strip}]
				end

				if dirs[1] && ! dirs[1].empty?
					@dir_src, @dir_dest = *(dirs[1].split(">").map {|s| s.strip })
				end
			end

			@parsed = true
		end
	end
end
