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

ActiveRecord::Schema[8.1].define(version: 2026_10_18_105253) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "fixed_cost_amounts", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "fixed_cost_id", null: false
    t.date "starts_on", null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fixed_cost_id", "starts_on"], name: "index_fixed_cost_amounts_on_fixed_cost_id_and_starts_on", unique: true
    t.index ["shop_id"], name: "index_fixed_cost_amounts_on_shop_id"
    t.check_constraint "EXTRACT(day FROM starts_on) = 1::numeric", name: "fixed_cost_amounts_starts_on_check"
    t.check_constraint "amount >= 0", name: "fixed_cost_amounts_amount_check"
  end

  create_table "fixed_costs", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.boolean "averaged", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_fixed_costs_on_shop_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "service_id", null: false
    t.date "done_on", null: false
    t.integer "quantity", null: false
    t.integer "price", null: false
    t.integer "material_cost", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_jobs_on_service_id"
    t.index ["shop_id", "done_on"], name: "index_jobs_on_shop_id_and_done_on"
    t.check_constraint "quantity >= 1 AND price >= 0 AND material_cost >= 0", name: "jobs_amounts_check"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.integer "price", null: false
    t.integer "material_cost", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "shop_id, lower((name)::text)", name: "index_services_on_shop_id_and_lower_name", unique: true, where: "active"
    t.index ["shop_id"], name: "index_services_on_shop_id"
    t.check_constraint "price >= 0 AND material_cost >= 0", name: "services_money_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.date "started_on", null: false
    t.integer "work_days", default: [1, 2, 3, 4, 5, 6], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "cardinality(work_days) > 0 AND work_days <@ ARRAY[0, 1, 2, 3, 4, 5, 6]", name: "shops_work_days_check"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["shop_id"], name: "index_users_on_shop_id", unique: true
  end

  add_foreign_key "fixed_cost_amounts", "fixed_costs"
  add_foreign_key "fixed_cost_amounts", "shops"
  add_foreign_key "fixed_costs", "shops"
  add_foreign_key "jobs", "services"
  add_foreign_key "jobs", "shops"
  add_foreign_key "services", "shops"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "shops"
end
