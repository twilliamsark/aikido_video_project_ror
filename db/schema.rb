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

ActiveRecord::Schema[8.1].define(version: 2026_06_18_140553) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "keywords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized_name"], name: "index_keywords_on_normalized_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.integer "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["teacher_id"], name: "index_sessions_on_teacher_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_teachers_on_email_address", unique: true
  end

  create_table "video_keywords", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "keyword_id", null: false
    t.datetime "updated_at", null: false
    t.integer "video_id", null: false
    t.index ["keyword_id"], name: "index_video_keywords_on_keyword_id"
    t.index ["video_id", "keyword_id"], name: "index_video_keywords_on_video_id_and_keyword_id", unique: true
    t.index ["video_id"], name: "index_video_keywords_on_video_id"
  end

  create_table "video_shares", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "shared_at"
    t.integer "teacher_id", null: false
    t.string "token", null: false
    t.datetime "unshared_at"
    t.datetime "updated_at", null: false
    t.integer "video_id", null: false
    t.index ["active"], name: "index_video_shares_on_active"
    t.index ["teacher_id"], name: "index_video_shares_on_teacher_id"
    t.index ["token"], name: "index_video_shares_on_token", unique: true
    t.index ["video_id"], name: "index_video_shares_on_video_id", unique: true
  end

  create_table "videos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description_plain_text"
    t.text "search_text"
    t.integer "teacher_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "youtube_url", null: false
    t.string "youtube_video_id", null: false
    t.index ["teacher_id"], name: "index_videos_on_teacher_id"
    t.index ["youtube_video_id"], name: "index_videos_on_youtube_video_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "sessions", "teachers"
  add_foreign_key "video_keywords", "keywords"
  add_foreign_key "video_keywords", "videos"
  add_foreign_key "video_shares", "teachers"
  add_foreign_key "video_shares", "videos"
  add_foreign_key "videos", "teachers"
end
