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

ActiveRecord::Schema[8.0].define(version: 2026_02_20_192956) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "lead_id", null: false
    t.integer "activity_type"
    t.text "description"
    t.string "performed_by"
    t.string "previous_value"
    t.string "new_value"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type"], name: "index_activities_on_activity_type"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["lead_id"], name: "index_activities_on_lead_id"
    t.index ["metadata"], name: "index_activities_on_metadata", using: :gin
  end

  create_table "leads", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "phone"
    t.string "email"
    t.decimal "budget"
    t.integer "agent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_leads_on_agent_id"
    t.index ["status"], name: "index_leads_on_status"
  end

  add_foreign_key "activities", "leads"
end
