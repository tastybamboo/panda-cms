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

ActiveRecord::Schema[8.0].define(version: 2025_11_18_015100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "panda_cms_block_kind", ["plain_text", "rich_text", "image", "video", "audio", "file", "code", "iframe", "quote", "list", "table", "form"]
  create_enum "panda_cms_menu_kind", ["static", "auto"]
  create_enum "panda_cms_og_type", ["website", "article", "profile", "video", "book"]
  create_enum "panda_cms_page_status", ["active", "draft", "hidden", "archived"]
  create_enum "panda_cms_post_status", ["active", "draft", "hidden", "archived"]
  create_enum "panda_cms_seo_index_mode", ["visible", "invisible"]

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "panda_cms_block_contents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "panda_cms_page_id", null: false
    t.uuid "panda_cms_block_id", null: false
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "cached_content"
    t.index ["panda_cms_block_id"], name: "index_panda_cms_block_contents_on_panda_cms_block_id"
    t.index ["panda_cms_page_id"], name: "index_panda_cms_block_contents_on_panda_cms_page_id"
  end

  create_table "panda_cms_blocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "kind", default: "plain_text", null: false, enum_type: "panda_cms_block_kind"
    t.string "name"
    t.string "key"
    t.uuid "panda_cms_template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["panda_cms_template_id"], name: "index_panda_cms_blocks_on_panda_cms_template_id"
  end

  create_table "panda_cms_form_submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "form_id", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.index ["form_id"], name: "index_panda_cms_form_submissions_on_form_id"
    t.index ["ip_address"], name: "index_panda_cms_form_submissions_on_ip_address"
  end

  create_table "panda_cms_forms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "submission_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "completion_path"
    t.index ["name"], name: "index_panda_cms_forms_on_name", unique: true
  end

  create_table "panda_cms_menu_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "text", null: false
    t.uuid "panda_cms_menu_id", null: false
    t.uuid "panda_cms_page_id"
    t.string "external_url"
    t.integer "sort_order", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.integer "depth"
    t.integer "children_count", default: 0, null: false
    t.index ["lft"], name: "index_panda_cms_menu_items_on_lft"
    t.index ["panda_cms_menu_id"], name: "index_panda_cms_menu_items_on_panda_cms_menu_id"
    t.index ["panda_cms_page_id"], name: "index_panda_cms_menu_items_on_panda_cms_page_id"
    t.index ["rgt"], name: "index_panda_cms_menu_items_on_rgt"
  end

  create_table "panda_cms_menus", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "kind", default: "static", null: false, enum_type: "panda_cms_menu_kind"
    t.uuid "start_page_id"
    t.integer "depth"
    t.index ["name"], name: "index_panda_cms_menus_on_name", unique: true
    t.index ["start_page_id"], name: "index_panda_cms_menus_on_start_page_id"
  end

  create_table "panda_cms_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "panda_cms_template_id", null: false
    t.uuid "parent_id"
    t.enum "status", default: "active", null: false, enum_type: "panda_cms_page_status"
    t.integer "lft"
    t.integer "rgt"
    t.integer "depth"
    t.integer "children_count", default: 0, null: false
    t.datetime "cached_last_updated_at"
    t.string "page_type", default: "standard", null: false
    t.string "seo_title"
    t.text "seo_description"
    t.string "seo_keywords"
    t.enum "seo_index_mode", default: "visible", null: false, enum_type: "panda_cms_seo_index_mode"
    t.string "canonical_url"
    t.string "og_title"
    t.text "og_description"
    t.enum "og_type", default: "website", null: false, enum_type: "panda_cms_og_type"
    t.boolean "inherit_seo", default: true, null: false
    t.index ["cached_last_updated_at"], name: "index_panda_cms_pages_on_cached_last_updated_at"
    t.index ["lft"], name: "index_panda_cms_pages_on_lft"
    t.index ["page_type"], name: "index_panda_cms_pages_on_page_type"
    t.index ["panda_cms_template_id"], name: "index_panda_cms_pages_on_panda_cms_template_id"
    t.index ["parent_id"], name: "index_panda_cms_pages_on_parent_id"
    t.index ["path"], name: "index_panda_cms_pages_on_path"
    t.index ["rgt"], name: "index_panda_cms_pages_on_rgt"
    t.index ["status"], name: "index_panda_cms_pages_on_status"
  end

  create_table "panda_cms_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.datetime "published_at"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "status", default: "draft", null: false, enum_type: "panda_cms_post_status"
    t.jsonb "content", default: {}, null: false
    t.text "cached_content"
    t.uuid "author_id"
    t.string "seo_title"
    t.text "seo_description"
    t.string "seo_keywords"
    t.enum "seo_index_mode", default: "visible", null: false, enum_type: "panda_cms_seo_index_mode"
    t.string "canonical_url"
    t.string "og_title"
    t.text "og_description"
    t.enum "og_type", default: "article", null: false, enum_type: "panda_cms_og_type"
    t.index ["author_id"], name: "index_panda_cms_posts_on_author_id"
    t.index ["slug"], name: "index_panda_cms_posts_on_slug", unique: true
    t.index ["status"], name: "index_panda_cms_posts_on_status"
    t.index ["user_id"], name: "index_panda_cms_posts_on_user_id"
  end

  create_table "panda_cms_redirects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "origin_path"
    t.string "destination_path"
    t.uuid "origin_panda_cms_page_id"
    t.uuid "destination_panda_cms_page_id"
    t.integer "status_code", default: 301, null: false
    t.integer "visits", default: 0, null: false
    t.datetime "last_visited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_panda_cms_page_id"], name: "index_panda_cms_redirects_on_destination_panda_cms_page_id"
    t.index ["origin_panda_cms_page_id"], name: "index_panda_cms_redirects_on_origin_panda_cms_page_id"
    t.index ["origin_path"], name: "index_panda_cms_redirects_on_origin_path"
  end

  create_table "panda_cms_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "file_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_uses"
    t.integer "pages_count", default: 0
  end

  create_table "panda_cms_visits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ip_address"
    t.string "user_agent"
    t.uuid "page_id"
    t.uuid "redirect_id"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "referrer"
    t.datetime "visited_at"
    t.string "url"
    t.jsonb "params"
    t.index ["page_id"], name: "index_panda_cms_visits_on_page_id"
    t.index ["redirect_id"], name: "index_panda_cms_visits_on_redirect_id"
    t.index ["user_id"], name: "index_panda_cms_visits_on_user_id"
    t.index ["visited_at"], name: "index_panda_cms_visits_on_visited_at"
  end

  create_table "panda_core_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "image_url"
    t.boolean "is_admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_theme"
    t.string "oauth_avatar_url"
    t.index ["email"], name: "index_panda_core_users_on_email", unique: true
  end

  create_table "panda_social_instagram_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "instagram_id", null: false
    t.text "caption"
    t.datetime "posted_at", null: false
    t.string "permalink"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instagram_id"], name: "index_panda_social_instagram_posts_on_instagram_id", unique: true
    t.index ["posted_at"], name: "index_panda_social_instagram_posts_on_posted_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "panda_cms_block_contents", "panda_cms_blocks"
  add_foreign_key "panda_cms_block_contents", "panda_cms_pages"
  add_foreign_key "panda_cms_blocks", "panda_cms_templates"
  add_foreign_key "panda_cms_form_submissions", "panda_cms_forms", column: "form_id"
  add_foreign_key "panda_cms_menu_items", "panda_cms_menus"
  add_foreign_key "panda_cms_menu_items", "panda_cms_pages"
  add_foreign_key "panda_cms_menus", "panda_cms_pages", column: "start_page_id"
  add_foreign_key "panda_cms_pages", "panda_cms_pages", column: "parent_id"
  add_foreign_key "panda_cms_pages", "panda_cms_templates"
  add_foreign_key "panda_cms_posts", "panda_core_users", column: "author_id"
  add_foreign_key "panda_cms_posts", "panda_core_users", column: "user_id"
  add_foreign_key "panda_cms_redirects", "panda_cms_pages", column: "destination_panda_cms_page_id"
  add_foreign_key "panda_cms_redirects", "panda_cms_pages", column: "origin_panda_cms_page_id"
  add_foreign_key "panda_cms_visits", "panda_cms_pages", column: "page_id"
  add_foreign_key "panda_cms_visits", "panda_cms_redirects", column: "redirect_id"
  add_foreign_key "panda_cms_visits", "panda_core_users", column: "user_id"
end
