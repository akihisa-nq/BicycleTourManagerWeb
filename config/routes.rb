BicycleTourManagerWeb::Application.routes.draw do
  devise_for :users

  get "/", to: "summary#index"
  get "/login", to: "summary#login"
  post "/edit_user", to: "summary#edit_user"

  get "/tour_result", to: "tour_result#index"
  post "/tour_result/create", to: "tour_result#create"
  get "/tour_result/:id/show", to: "tour_result#show"
  get "/tour_result/:id/gpx.xml", to: "tour_result#gpx_file"
  post "/tour_result/:id/create_images", to: "tour_result#create_images"
end
