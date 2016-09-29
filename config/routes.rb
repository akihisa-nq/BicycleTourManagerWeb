BicycleTourManagerWeb::Application.routes.draw do
  use_doorkeeper

  root to: "summary#index"

  devise_for :users

  get "/", to: "summary#index"
  get "/login", to: "summary#login"

  get "/management", to: "management#index"

  post "/management/users/edit", to: "management#edit_user"

  post "/exclusion_area/create", to: "management#create_exclusion_area"
  delete "/exclusion_area/:id/destroy", to: "management#destroy_exclusion_area"
  post "/exclusion_area/update", to: "management#update_exclusion_area"

  post "/resource_sets/resources/update", to: "management#update_resources"
  delete "/resource_sets/resources/:id/destroy", to: "management#destroy_resource"

  post "/resource_sets/devicess/update", to: "management#update_devices"
  delete "/resource_sets/devices/:id/destroy", to: "management#destroy_device"

  delete "/resource_sets/:resource_set_id/resource_entries/:id/destroy", to: "management#destroy_resource_entry"
  delete "/resource_sets/:resource_set_id/device_entries/:id/destroy", to: "management#destroy_device_entry"
  post "/resource_sets/create", to: "management#create_resource_set"
  get "/resource_sets/edit", to: "management#edit_resource_set"
  post "/resource_sets/:id/update", to: "management#update_resource_set"

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

  get "/tour_plan", to: "tour_plan#index"
  post "/tour_plan/create", to: "tour_plan#create"
  delete "/tour_plan/:id/destroy", to: "tour_plan#destroy"
  post "/tour_plan/:id/toggle_visible", to: "tour_plan#toggle_visible"
  get "/tour_plan/:id/show", to: "tour_plan#show"
  get "/tour_plan/:id/show/gpx", to: "tour_plan#show_gpx"
  get "/tour_plan/:id/show/private_gpx", to: "tour_plan#show_private_gpx"
  get "/tour_plan/:id/show/pdf", to: "tour_plan#show_pdf"
  post "/tour_plan/:id/generate", to: "tour_plan#generate"

  get "/tour_plan/:id/routes/paths/edit", to: "tour_plan#edit_path"
  post "/tour_plan/:id/routes/paths/update", to: "tour_plan#update_path"
  delete "/tour_plan/:tour_plan_id/routes/paths/:id/destroy", to: "tour_plan#destroy_path"

  get "/tour_plan/:id/routes/nodes/edit", to: "tour_plan#edit_node"
  post "/tour_plan/:id/routes/nodes/update", to: "tour_plan#update_node"
  delete "/tour_plan/:tour_plan_id/routes/nodes/:id/destroy", to: "tour_plan#destroy_node"

  get "/tour_go", to: "tour_go#index"
  get "/tour_go/page/:page", to: "tour_go#index"
  delete "/tour_go/:id/destroy", to: "tour_go#destroy"
  
  namespace :api do
	  resources :exclusion_area, only: [ :show ] do
		  collection do
			  get :list
		  end
	  end

	  resources :tour_plan, only: [ :show ] do
		  collection do
			  get :list
		  end

		  get "schedule"
	  end

	  resources :tour_go, only: [ :show, :create ] do
		  collection do
			  get :list
		  end
	  end
  end
end

