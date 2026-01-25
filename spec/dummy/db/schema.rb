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

ActiveRecord::Schema[8.1].define(version: 2026_01_23_180000) do
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
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

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

  create_table "panda_cms_block_contents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "cached_content"
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.uuid "panda_cms_block_id", null: false
    t.uuid "panda_cms_page_id", null: false
    t.datetime "updated_at", null: false
    t.index ["panda_cms_block_id"], name: "index_panda_cms_block_contents_on_panda_cms_block_id"
    t.index ["panda_cms_page_id"], name: "index_panda_cms_block_contents_on_panda_cms_page_id"
  end

  create_table "panda_cms_block_images", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "panda_cms_block_content_id", null: false
    t.integer "position", default: 0, null: false
    t.string "key"
    t.string "alt_text"
    t.text "caption"
    t.string "link_url"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["panda_cms_block_content_id", "key"], name: "index_panda_cms_block_images_on_content_id_and_key", unique: true, where: "(key IS NOT NULL)"
    t.index ["panda_cms_block_content_id", "position"], name: "index_panda_cms_block_images_on_content_id_and_position"
  end

  create_table "panda_cms_blocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.enum "kind", default: "plain_text", null: false, enum_type: "panda_cms_block_kind"
    t.string "name"
    t.uuid "panda_cms_template_id", null: false
    t.datetime "updated_at", null: false
    t.index ["panda_cms_template_id"], name: "index_panda_cms_blocks_on_panda_cms_template_id"
  end

  create_table "panda_cms_form_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "field_type", null: false
    t.uuid "form_id", null: false
    t.text "hint"
    t.string "label", null: false
    t.string "name", null: false
    t.text "options"
    t.text "placeholder"
    t.integer "position", default: 0
    t.boolean "required", default: false
    t.datetime "updated_at", null: false
    t.text "validations"
    t.index ["form_id", "name"], name: "index_panda_cms_form_fields_on_form_id_and_name", unique: true
    t.index ["form_id", "position"], name: "index_panda_cms_form_fields_on_form_id_and_position"
    t.index ["form_id"], name: "index_panda_cms_form_fields_on_form_id"
  end

  create_table "panda_cms_form_submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.jsonb "files_metadata", default: {}
    t.uuid "form_id", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["form_id"], name: "index_panda_cms_form_submissions_on_form_id"
    t.index ["ip_address"], name: "index_panda_cms_form_submissions_on_ip_address"
  end

  create_table "panda_cms_forms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "completion_path"
    t.text "confirmation_body"
    t.string "confirmation_email_field"
    t.string "confirmation_subject"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.text "notification_emails"
    t.string "notification_subject"
    t.boolean "send_confirmation", default: false
    t.string "status", default: "active"
    t.integer "submission_count", default: 0
    t.text "success_message"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_panda_cms_forms_on_name", unique: true
  end

  create_table "panda_cms_menu_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "children_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "depth"
    t.string "external_url"
    t.integer "lft"
    t.uuid "panda_cms_menu_id", null: false
    t.uuid "panda_cms_page_id"
    t.uuid "parent_id"
    t.integer "rgt"
    t.integer "sort_order", default: 1
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["lft"], name: "index_panda_cms_menu_items_on_lft"
    t.index ["panda_cms_menu_id"], name: "index_panda_cms_menu_items_on_panda_cms_menu_id"
    t.index ["panda_cms_page_id"], name: "index_panda_cms_menu_items_on_panda_cms_page_id"
    t.index ["rgt"], name: "index_panda_cms_menu_items_on_rgt"
  end

  create_table "panda_cms_menus", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depth"
    t.enum "kind", default: "static", null: false, enum_type: "panda_cms_menu_kind"
    t.string "name", null: false
    t.uuid "start_page_id"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_panda_cms_menus_on_name", unique: true
    t.index ["start_page_id"], name: "index_panda_cms_menus_on_start_page_id"
  end

  create_table "panda_cms_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "cached_last_updated_at"
    t.string "canonical_url"
    t.integer "children_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "depth"
    t.boolean "inherit_seo", default: true, null: false
    t.integer "lft"
    t.text "og_description"
    t.string "og_title"
    t.enum "og_type", default: "website", null: false, enum_type: "panda_cms_og_type"
    t.string "page_type", default: "standard", null: false
    t.uuid "panda_cms_template_id", null: false
    t.uuid "parent_id"
    t.string "path"
    t.integer "rgt"
    t.text "seo_description"
    t.enum "seo_index_mode", default: "visible", null: false, enum_type: "panda_cms_seo_index_mode"
    t.string "seo_keywords"
    t.string "seo_title"
    t.enum "status", default: "active", null: false, enum_type: "panda_cms_page_status"
    t.string "title"
    t.datetime "updated_at", null: false
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
    t.uuid "author_id"
    t.text "cached_content"
    t.string "canonical_url"
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "og_description"
    t.string "og_title"
    t.enum "og_type", default: "article", null: false, enum_type: "panda_cms_og_type"
    t.datetime "published_at"
    t.text "seo_description"
    t.enum "seo_index_mode", default: "visible", null: false, enum_type: "panda_cms_seo_index_mode"
    t.string "seo_keywords"
    t.string "seo_title"
    t.string "slug"
    t.enum "status", default: "draft", null: false, enum_type: "panda_cms_post_status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["author_id"], name: "index_panda_cms_posts_on_author_id"
    t.index ["slug"], name: "index_panda_cms_posts_on_slug", unique: true
    t.index ["status"], name: "index_panda_cms_posts_on_status"
    t.index ["user_id"], name: "index_panda_cms_posts_on_user_id"
  end

  create_table "panda_cms_redirects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "destination_panda_cms_page_id"
    t.string "destination_path"
    t.datetime "last_visited_at"
    t.uuid "origin_panda_cms_page_id"
    t.string "origin_path"
    t.integer "status_code", default: 301, null: false
    t.datetime "updated_at", null: false
    t.integer "visits", default: 0, null: false
    t.index ["destination_panda_cms_page_id"], name: "index_panda_cms_redirects_on_destination_panda_cms_page_id"
    t.index ["origin_panda_cms_page_id"], name: "index_panda_cms_redirects_on_origin_panda_cms_page_id"
    t.index ["origin_path"], name: "index_panda_cms_redirects_on_origin_path"
  end

  create_table "panda_cms_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_path"
    t.integer "max_uses"
    t.string "name"
    t.integer "pages_count", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "panda_cms_visits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.uuid "page_id"
    t.jsonb "params"
    t.uuid "redirect_id"
    t.string "referrer"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "user_agent"
    t.uuid "user_id"
    t.datetime "visited_at"
    t.index ["page_id"], name: "index_panda_cms_visits_on_page_id"
    t.index ["redirect_id"], name: "index_panda_cms_visits_on_redirect_id"
    t.index ["user_id"], name: "index_panda_cms_visits_on_user_id"
    t.index ["visited_at"], name: "index_panda_cms_visits_on_visited_at"
  end

  create_table "panda_core_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "current_theme"
    t.string "email", null: false
    t.string "image_url"
    t.boolean "is_admin", default: false, null: false
    t.string "name"
    t.string "oauth_avatar_url"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_panda_core_users_on_email", unique: true
  end

  create_table "panda_social_instagram_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "caption"
    t.datetime "created_at", null: false
    t.string "instagram_id", null: false
    t.string "permalink"
    t.datetime "posted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instagram_id"], name: "index_panda_social_instagram_posts_on_instagram_id", unique: true
    t.index ["posted_at"], name: "index_panda_social_instagram_posts_on_posted_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "panda_cms_block_contents", "panda_cms_blocks"
  add_foreign_key "panda_cms_block_contents", "panda_cms_pages"
  add_foreign_key "panda_cms_block_images", "panda_cms_block_contents"
  add_foreign_key "panda_cms_blocks", "panda_cms_templates"
  add_foreign_key "panda_cms_form_fields", "panda_cms_forms", column: "form_id"
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
