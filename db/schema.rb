# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140406173339) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "private_result_routes", force: true do |t|
    t.integer  "tour_result_id"
    t.integer  "position"
    t.datetime "start_time"
    t.datetime "finish_time"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "path",           limit: {:srid=>4326, :type=>"line_string"}
  end

  create_table "public_result_routes", force: true do |t|
    t.integer  "tour_result_id"
    t.integer  "position"
    t.datetime "start_time"
    t.datetime "finish_time"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.spatial  "path",           limit: {:srid=>4326, :type=>"line_string"}
  end

  create_table "result_points", force: true do |t|
    t.float    "elevation"
    t.float    "speed"
    t.datetime "time"
    t.integer  "public_result_route_id"
    t.integer  "private_result_route_id"
    t.spatial  "point",                   limit: {:srid=>4326, :type=>"point"}
  end

  create_table "tour_images", force: true do |t|
    t.integer  "tour_result_id"
    t.datetime "shot_on"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tour_results", force: true do |t|
    t.datetime "start_time"
    t.datetime "finish_time"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "published"
    t.string   "time_zone"
  end

  create_table "users", force: true do |t|
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
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
