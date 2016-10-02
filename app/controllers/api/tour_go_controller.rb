module Api
	class TourGoController < Api::BaseController
		def list
			offset = params[:offset] || 0
			limit = params[:limit].to_i || 1000
			tour_gos = TourGo
				.all_with_auth(current_user, offset, limit)
				.map {|tour_go| filter_attributes_tour_go(tour_go) }
			render json: { tour_gos: tour_gos, total_count: TourGo.count, offset: offset, limit: limit }.to_json
		end

		def show
			tour_go = TourGo
				.find_with_auth(current_user, params[:id])
			attrs = filter_attributes_tour_go(tour_go)
			render json: attrs.to_json
		end

		def create
			tour_go = TourGo.create_with_auth(current_user, tour_go_params)

			if tour_go && params["tour_go"]["tour_go_events"]
				tour_go_events_params {|e| tour_go.tour_go_events.build(e) }
				tour_go.save!
			end

			render json: { id: tour_go ? tour_go.id : nil }.to_json
		end

		def update
			tour_go = TourGo
				.find_with_auth(current_user, params[:id])

			if tour_go
				tour_go.tour_go_events.clear
				tour_go_events_params {|e| tour_go.tour_go_events.build(e) }

				tour_go.update(tour_go_params)
			end

			render json: { result: tour_go ? true : false }.to_json
		end

		def destroy
			TourGo.destroy_with_auth(current_user, params[:id])
			render json: { result: true }.to_json
		end

		private

		def tour_go_params
			params.require(:tour_go).permit(:tour_plan_id, :start_time)
		end

		def tour_go_events_params(&block)
			params.require(:tour_go).require("tour_go_events").each do |e|
				block.call(e.permit(:occured_on, :event_type, :tour_plan_point_id))
			end
		end

		def filter_attributes_tour_go(tour_go)
			attrs = tour_go.as_json

			attrs["tour_go_events"] = []
			tour_go.tour_go_events.each do |tour_go_event|
				attrs["tour_go_events"] << tour_go_event.as_json
			end

			attrs
		end
	end
end
