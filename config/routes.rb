BicycleTourManagerWeb::Application.routes.draw do
  root to: "summary#index"

  devise_for :users

  get "/", to: "summary#index"
  get "/login", to: "summary#login"
  post "/edit_user", to: "summary#edit_user"
  get "/management", to: "summary#management"

  post "/exclusion_area/create", to: "summary#create_exclusion_area"
  delete "/exclusion_area/:id/destroy", to: "summary#destroy_exclusion_area"
  post "/exclusion_area/update", to: "summary#update_exclusion_area"

  get "/tour_result", to: "tour_result#index"
  get "/tour_result/page/:page", to: "tour_result#index"
  post "/tour_result/create", to: "tour_result#create"
  delete "/tour_result/:id/destroy", to: "tour_result#destroy"
  get "/tour_result/:id/show", to: "tour_result#show"
  get "/tour_result/:id/gpx.xml", to: "tour_result#gpx_file"
  post "/tour_result/:id/toggle_visible", to: "tour_result#toggle_visible"

  post "/tour_result/:id/create_images", to: "tour_result#create_images"
  delete "/tour_result/:id/destroy_image/:image_id", to: "tour_result#destroy_image"
  post "/tour_result/update_image_text/:id", to: "tour_result#update_image_text"
end
