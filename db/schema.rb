# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161109090257) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "device_entries", force: :cascade do |t|
    t.integer "resource_set_id"
    t.integer "device_id"
    t.string  "purpose"
    t.time    "start_time"
    t.boolean "use_on_start"
  end

  create_table "devices", force: :cascade do |t|
    t.string  "name"
    t.integer "resource_id"
    t.integer "interval"
    t.integer "consumption"
  end

  create_table "exclusion_areas", force: :cascade do |t|
    t.point "point"
    t.float "distance"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",                               null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",                          null: false
    t.string   "scopes"
    t.string   "previous_refresh_token", default: "", null: false
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                      null: false
    t.string   "uid",                       null: false
    t.string   "secret",                    null: false
    t.text     "redirect_uri",              null: false
    t.string   "scopes",       default: "", null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree
  end

  create_table "private_result_routes", force: :cascade do |t|
    t.integer  "tour_result_id"
    t.integer  "position"
    t.datetime "start_time"
    t.datetime "finish_time"
    t.string   "name"
    t.geometry "path",           limit: {:srid=>4326, :type=>"line_string", :has_z=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "speed",                                                                    array: true
    t.datetime "time",                                                                     array: true
    t.index ["speed"], name: "index_private_result_routes_on_speed", using: :gin
    t.index ["time"], name: "index_private_result_routes_on_time", using: :gin
  end

  create_table "public_result_routes", force: :cascade do |t|
    t.integer  "tour_result_id"
    t.integer  "position"
    t.datetime "start_time"
    t.datetime "finish_time"
    t.string   "name"
    t.geometry "path",           limit: {:srid=>4326, :type=>"line_string", :has_z=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "speed",                                                                    array: true
    t.datetime "time",                                                                     array: true
    t.index ["speed"], name: "index_public_result_routes_on_speed", using: :gin
    t.index ["time"], name: "index_public_result_routes_on_time", using: :gin
  end

  create_table "resource_entries", force: :cascade do |t|
    t.integer "resource_set_id"
    t.integer "resource_id"
    t.integer "amount"
    t.integer "buffer"
    t.integer "recovery_interval"
  end

  create_table "resource_sets", force: :cascade do |t|
    t.string "name"
  end

  create_table "resources", force: :cascade do |t|
    t.string "name"
  end

  create_table "tour_go_events", force: :cascade do |t|
    t.integer  "tour_go_id"
    t.datetime "occured_on"
    t.integer  "event_type",         limit: 2, default: 0, null: false
    t.integer  "tour_plan_point_id"
    t.binary   "blob"
  end

  create_table "tour_gos", force: :cascade do |t|
    t.integer  "tour_plan_id"
    t.datetime "start_time"
  end

  create_table "tour_images", force: :cascade do |t|
    t.integer  "tour_result_id"
    t.datetime "shot_on"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tour_plan_caches", force: :cascade do |t|
    t.text  "request"
    t.text  "response"
    t.point "point"
  end

  create_table "tour_plan_paths", force: :cascade do |t|
    t.integer "tour_plan_route_id"
    t.text    "google_map_url"
    t.integer "position"
  end

  create_table "tour_plan_points", force: :cascade do |t|
    t.integer  "tour_plan_route_id"
    t.geometry "point",              limit: {:srid=>4326, :type=>"point", :has_z=>true}
    t.string   "name"
    t.string   "comment"
    t.string   "direction"
    t.float    "rest_time"
    t.float    "target_speed"
    t.float    "limit_speed"
    t.integer  "position"
    t.datetime "target_time"
    t.datetime "limit_time"
    t.integer  "distance"
    t.boolean  "pass"
    t.integer  "peak_type",          limit: 2,                                           default: 0, null: false
  end

  create_table "tour_plan_routes", force: :cascade do |t|
    t.integer  "tour_plan_id"
    t.string   "name"
    t.integer  "position"
    t.geometry "public_line",  limit: {:srid=>4326, :type=>"line_string", :has_z=>true}
    t.geometry "private_line", limit: {:srid=>4326, :type=>"line_string", :has_z=>true}
  end

  create_table "tour_plan_tiles", force: :cascade do |t|
    t.integer "x",      null: false
    t.integer "y",      null: false
    t.integer "zoom",   null: false
    t.binary  "image",  null: false
    t.boolean "public", null: false
    t.index ["x", "y", "zoom", "public"], name: "index_tour_plan_tiles_on_x_and_y_and_zoom_and_public", using: :btree
  end

  create_table "tour_plan_up_hills", force: :cascade do |t|
    t.geometry "point",              limit: {:srid=>4326, :type=>"point", :has_z=>true}
    t.integer  "distance"
    t.float    "length"
    t.integer  "tour_plan_point_id"
    t.float    "gradient"
    t.integer  "position"
  end

  create_table "tour_plans", force: :cascade do |t|
    t.string   "name"
    t.boolean  "published"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_zone"
    t.time     "start_time"
    t.integer  "elevation"
    t.integer  "resource_set_id"
    t.float    "planning_sheet_scale"
  end

  create_table "tour_results", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "finish_time"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "published"
    t.string   "time_zone"
    t.integer  "tour_plan_id"
    t.integer  "elevation"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
