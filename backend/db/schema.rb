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

ActiveRecord::Schema[8.0].define(version: 2025_10_12_144827) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", null: false
    t.string "icon"
    t.text "description"
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_categories_on_display_order"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "category_keywords", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "keyword", null: false
    t.integer "priority", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "keyword"], name: "index_category_keywords_on_category_id_and_keyword", unique: true
    t.index ["category_id"], name: "index_category_keywords_on_category_id"
    t.index ["keyword"], name: "index_category_keywords_on_keyword"
  end

  create_table "category_rules", force: :cascade do |t|
    t.string "keyword", null: false
    t.integer "category_id", null: false
    t.integer "priority", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_category_rules_on_category_id"
    t.index ["keyword"], name: "index_category_rules_on_keyword"
    t.index ["priority"], name: "index_category_rules_on_priority"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "category_id"
    t.date "transaction_date", null: false
    t.string "store_name", limit: 500, null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "payment_method", limit: 100
    t.string "user_name", limit: 100
    t.string "payment_month", limit: 50
    t.text "raw_data"
    t.boolean "auto_classified", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upload_history_id"
    t.index ["amount"], name: "index_transactions_on_amount"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["transaction_date", "amount"], name: "index_transactions_on_transaction_date_and_amount"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
    t.index ["upload_history_id"], name: "index_transactions_on_upload_history_id"
  end

  create_table "upload_histories", force: :cascade do |t|
    t.string "filename", null: false
    t.datetime "upload_date", null: false
    t.integer "imported_count", default: 0
    t.string "file_hash"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "data_source_type", default: "rakuten", null: false
    t.index ["file_hash"], name: "index_upload_histories_on_file_hash"
    t.index ["upload_date"], name: "index_upload_histories_on_upload_date"
  end

  add_foreign_key "category_keywords", "categories"
  add_foreign_key "category_rules", "categories"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "upload_histories"
end
