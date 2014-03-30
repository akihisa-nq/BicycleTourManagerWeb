require "exifr"
require "fileutils"

def binary_search_by(arr, offset, target, &block)
	return offset if arr.size == 1
	center = arr.size / 2

	ret = target <=> block.call(arr[center])
	if ret == 0
		return offset + center
	elsif ret < 0
		if arr.size == 2
			return offset
		else
			return binary_search_by(arr[0..center], offset, target, &block)
		end
	elsif ret > 0
		if arr.size == 2
			return offset + 1
		else
			return binary_search_by(arr[center..-1], offset + center, target, &block)
		end
	end
end

class TourImage < ActiveRecord::Base
	belongs_to :tour_result

	after_save :save_image

	def image_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, image_url)
	end

	def image_url
		"/generated/tour_result/tour_image/#{id}.png"
	end

	def thumbnail_path
		public_root = File.join(Rails.root, "public")
		File.join(public_root, thumbnail_url)
	end

	def thumbnail_url
		"/generated/tour_result/tour_image_thumbnails/#{id}.png"
	end

	def point
		route = tour_result.public_result_routes.where(["start_time <= ? AND ? <= finish_time", shot_on, shot_on]).first
		if route
			i = binary_search_by(route.result_points, 0, shot_on) {|s| s.time }
			if route.result_points[i].time == shot_on
				route.result_points[i].point
			elsif route.result_points[i].time > shot_on
				p = route.result_points[i - 1].point
				n = route.result_points[i].point
				BTM.factory.point((p.x + p.x) / 2, (p.y + p.y) / 2)
			else
				p = route.result_points[i].point
				n = route.result_points[i + 1].point
				BTM.factory.point((p.x + p.x) / 2, (p.y + p.y) / 2)
			end
		else
			nil
		end
	end

	attr_accessor :image_data

	private

	def save_image
		if @image_data
			FileUtils.mkdir_p(File.dirname(image_path))
			File.open(image_path, "wb") do |file|
				file.write(@image_data.read)
			end

			FileUtils.mkdir_p(File.dirname(thumbnail_path))
			system("convert -resize 320x240 #{image_path} #{thumbnail_path}")

			@image_data = nil

			exif = EXIFR::JPEG.new(image_path)
			if self.shot_on != exif.date_time_original
				self.shot_on = exif.date_time_original
				self.save
			end
		end
	end
end