BicycleTourManagerWeb::Application.routes.draw do
  devise_for :users

  get "/", to: "summary#index"
  get "/login", to: "summary#login"
  post "/edit_user", to: "summary#edit_user"

  get "/tour_result", to: "tour_result#index"
  post "/tour_result/create", to: "tour_result#create"
  delete "/tour_result/destroy", to: "tour_result#destroy"
  get "/tour_result/:id/show", to: "tour_result#show"
  get "/tour_result/:id/gpx.xml", to: "tour_result#gpx_file"
  post "/tour_result/:id/toggle_visible", to: "tour_result#toggle_visible"

  post "/tour_result/:id/create_images", to: "tour_result#create_images"
  delete "/tour_result/:id/destroy_image/:image_id", to: "tour_result#destroy_image"
end
