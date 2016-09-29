module Api
	class TourGoController < Api::BaseController
		def list
			offset = params[:offset] || 0
			limit = params[:limit] || 1000
			tour_gos = TourGo
				.all_with_auth(current_user, offset, limit)
				.map {|tour_go| filter_attributes_tour_go(tour_go) }
			render json: { tour_gos: tour_gos, total_count: TourGo.count, offset: offset, limit: limit }.to_json
		end

		def show
			tour_go = TourGo
				.find_with_auth(current_user, params[:id])
			attrs = filter_attributes_tour_go(tour_go)

			attrs["tour_go_events"] = []
			tour_go.tour_go_events.each do |tour_go_event|
				attrs["tour_go_events"] << tour_go_event.attributes
			end

			render json: attrs.to_json
		end

		def create
			tour_go = TourGo.create_with_auth(current_user, params)
			render json: { id: tour_go.id }.to_json
		end

		private

		def filter_attributes_tour_go(tour_go)
			attrs = tour_go.attributes
			attrs
		end
	end
end
