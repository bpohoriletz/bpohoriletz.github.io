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

ActiveRecord::Schema.define(version: 20151128114851) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers_accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password", null: false
    t.string "password_salt", null: false
    t.string "persistence_token", null: false
    t.string "single_access_token", null: false
    t.string "perishable_token", null: false
    t.integer "login_count", default: 0, null: false
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string "current_login_ip"
    t.string "last_login_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_accounts_on_email", unique: true
  end

  create_table "customers_authentications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_customers_authentications_on_provider_and_uid"
  end

  create_table "customers_profiles", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.integer "permissin_level", default: 0
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "settings"
    t.string "google_login"
    t.index ["account_id"], name: "index_customers_profiles_on_account_id"
    t.index ["google_login"], name: "index_customers_profiles_on_google_login", unique: true
    t.index ["permissin_level"], name: "index_customers_profiles_on_permissin_level"
  end

  add_foreign_key "customers_profiles", "customers_accounts", column: "account_id"
end
