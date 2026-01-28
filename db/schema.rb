# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_26_215554) do
  create_table "email_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "last_sent_at"
    t.integer "region", null: false
    t.string "unsubscribe_token", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address", "region"], name: "index_email_subscriptions_on_email_address_and_region", unique: true
    t.index ["region"], name: "index_email_subscriptions_on_region"
    t.index ["unsubscribe_token"], name: "index_email_subscriptions_on_unsubscribe_token", unique: true
  end

  create_table "event_locations", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "region", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "region"], name: "index_event_locations_on_event_id_and_region"
    t.index ["event_id"], name: "index_event_locations_on_event_id"
    t.index ["region", "city"], name: "index_event_locations_on_region_and_city"
    t.index ["region"], name: "index_event_locations_on_region"
  end

  create_table "events", force: :cascade do |t|
    t.text "address"
    t.boolean "approved", default: false, null: false
    t.string "city"
    t.string "cost"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.date "end_date"
    t.time "end_time"
    t.integer "event_type", default: 0, null: false
    t.integer "region"
    t.string "registration_url"
    t.text "short_summary"
    t.date "start_date", null: false
    t.time "start_time"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["region"], name: "index_events_on_region"
    t.index ["start_date", "region"], name: "index_events_on_start_date_and_region"
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "approved_organiser", default: false, null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "google_uid"
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true, where: "google_uid IS NOT NULL"
  end

  add_foreign_key "event_locations", "events"
  add_foreign_key "events", "users"
  add_foreign_key "sessions", "users"
end
