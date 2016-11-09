module TileModule
	extend ActiveSupport::Concern

	module ClassMethods
		def generate_empty
			ret = self
				.select(<<EOF)
ST_AsPNG(
	ST_AddBand(
		ST_MakeEmptyRaster(256, 256, 0, 0, 0, 0, 0, 0, 4326),
		ARRAY [
			ROW(1, '8BUI', 191, NULL),
			ROW(2, '8BUI', 191, NULL),
			ROW(3, '8BUI', 191, NULL)
		] :: addbandarg[])
	) as image
EOF
				.order("")
				.from("UNNEST(ARRAY[1])")
				.first
			ret.image			
		end

		def generate(tx, ty, zoom, is_public_data, line)
			x1, y1, x2, y2, w, h = *BTM::GoogleMapHelper.tile_bounding_box(tx, ty, zoom)
			view = BTM::GoogleMapHelper.tile(x1, y1, x2, y2)

			ret = self
				.select("ST_Intersects(ST_GeomFromText('#{line}', 4326), ST_GeomFromText('#{view}', 4326)) as intersect")
				.order("")
				.from("UNNEST(ARRAY[1])")
				.first
				.intersect
			return false unless ret

			value = <<EOF
ST_AsPNG(
	ST_AddBand(
		ST_MapAlgebra(
			ST_AddBand(
				ST_MakeEmptyRaster(256, 256, #{x1}, #{y1}, #{w / 256.0}, #{- h / 256.0}, 0, 0, 4326),
				1, '8BUI', 255, NULL),
			ST_AsRaster(
				ST_Intersection(
					ST_GeomFromText('#{line}', 4326),
					ST_GeomFromText('#{view}', 4326)),
				ST_MakeEmptyRaster(256, 256, #{x1}, #{y1}, #{w / 256.0}, #{- h / 256.0}, 0, 0, 4326),
				'8BUI',
				1, 255),
			'[rast2]', '8BUI', 'FIRST', '[rast2]', '255', NULL),
		ARRAY [
			ROW(1, '8BUI', 191, NULL),
			ROW(2, '8BUI', 191, NULL),
			ROW(3, '8BUI', 191, NULL)
		] :: addbandarg[])
	)
EOF

			name = self.to_s.tableize
			con = ActiveRecord::Base.connection
			ret = self.select("id").find_by(x: tx, y: ty, zoom: zoom, public: is_public_data)
			if ret
				con.execute("UPDATE #{name} SET image = #{value} WHERE id = #{ret.id}")
			else
				con.execute("INSERT INTO #{name} (x, y, zoom, public, image) VALUES (#{tx}, #{ty}, #{zoom}, #{is_public_data}, #{value})")
			end

			true
		end

		def generate_range(is_public_data, extent_text, zoom_min, zoom_max, line)
			extent_geometry = BTM.factory.parse_wkt(extent_text)
			extent = [0, 2].map {|i| pt = extent_geometry.exterior_ring.points[i] }

			previous = {}
			(zoom_min..zoom_max).each do |zoom|
				tx1, ty1, tx2, ty2, tw, th = *BTM::GoogleMapHelper.lonlat_bounding_box(
					extent[0].x, extent[1].y, extent[1].x, extent[0].y, zoom
					)
				current = {}
				(tx1..tx2).each do |tx|
					(ty1..ty2).each do |ty|
						if zoom == zoom_min || previous.include?([tx / 2, ty / 2, zoom - 1, is_public_data])
							if generate(tx, ty, zoom, is_public_data, line)
								current[[tx, ty, zoom, is_public_data]] = true
							end
						end
					end
				end
				previous = current
			end
		end

		def tile(x, y, zoom, is_public_data)
			ret = find_by(x: x, y: y, zoom: zoom, public: is_public_data)
			if ret
				ret.image
			else
				generate_empty
			end
		end

		def include?(x, y, zoom, is_public_data)
			select("id").find_by(x: x, y: y, zoom: zoom, public: is_public_data) != nil
		end
	end
end
