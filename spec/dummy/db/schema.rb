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
  create_enum "panda_cms_pro_content_change_type", ["addition", "deletion", "modification", "callout", "citation"]
  create_enum "panda_cms_pro_source_trust_level", ["always_prefer", "trusted", "neutral", "untrusted", "never_use"]
  create_enum "panda_cms_pro_suggestion_status", ["pending", "specialist_review", "admin_review", "approved", "rejected"]
  create_enum "panda_cms_pro_suggestion_type", ["edit", "addition", "deletion", "comment", "citation"]
  create_enum "panda_cms_pro_sync_status", ["pending", "in_progress", "completed", "failed", "rolled_back"]
  create_enum "panda_cms_pro_sync_type", ["push", "pull"]
  create_enum "panda_cms_seo_index_mode", ["visible", "invisible"]

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
    t.integer "contributor_count", default: 0
    t.datetime "last_contributed_at"
    t.string "workflow_status", default: "draft"
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
    t.index ["last_contributed_at"], name: "index_panda_cms_pages_on_last_contributed_at"
    t.index ["lft"], name: "index_panda_cms_pages_on_lft"
    t.index ["page_type"], name: "index_panda_cms_pages_on_page_type"
    t.index ["panda_cms_template_id"], name: "index_panda_cms_pages_on_panda_cms_template_id"
    t.index ["parent_id"], name: "index_panda_cms_pages_on_parent_id"
    t.index ["rgt"], name: "index_panda_cms_pages_on_rgt"
    t.index ["status"], name: "index_panda_cms_pages_on_status"
    t.index ["workflow_status"], name: "index_panda_cms_pages_on_workflow_status"
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
    t.integer "contributor_count", default: 0
    t.datetime "last_contributed_at"
    t.string "workflow_status", default: "draft"
    t.string "seo_title"
    t.text "seo_description"
    t.string "seo_keywords"
    t.enum "seo_index_mode", default: "visible", null: false, enum_type: "panda_cms_seo_index_mode"
    t.string "canonical_url"
    t.string "og_title"
    t.text "og_description"
    t.enum "og_type", default: "article", null: false, enum_type: "panda_cms_og_type"
    t.index ["author_id"], name: "index_panda_cms_posts_on_author_id"
    t.index ["last_contributed_at"], name: "index_panda_cms_posts_on_last_contributed_at"
    t.index ["slug"], name: "index_panda_cms_posts_on_slug", unique: true
    t.index ["status"], name: "index_panda_cms_posts_on_status"
    t.index ["user_id"], name: "index_panda_cms_posts_on_user_id"
    t.index ["workflow_status"], name: "index_panda_cms_posts_on_workflow_status"
  end

  create_table "panda_cms_pro_collection_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "collection_id", null: false
    t.string "label", null: false
    t.string "field_type", null: false
    t.string "key", null: false
    t.boolean "required", default: false, null: false
    t.integer "position", default: 0, null: false
    t.text "instructions"
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "key"], name: "idx_panda_cms_pro_collection_fields_keys", unique: true
    t.index ["collection_id"], name: "index_panda_cms_pro_collection_fields_on_collection_id"
  end

  create_table "panda_cms_pro_collection_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "collection_id", null: false
    t.string "title", null: false
    t.jsonb "data", default: {}, null: false
    t.boolean "visible", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "position"], name: "idx_panda_cms_pro_collection_items_position"
    t.index ["collection_id"], name: "index_panda_cms_pro_collection_items_on_collection_id"
  end

  create_table "panda_cms_pro_collections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "item_label"
    t.text "description"
    t.integer "items_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_panda_cms_pro_collections_on_slug", unique: true
  end

  create_table "panda_cms_pro_content_changes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "panda_cms_pro_content_version_id", null: false
    t.string "section_identifier"
    t.enum "change_type", null: false, enum_type: "panda_cms_pro_content_change_type"
    t.text "old_content"
    t.text "new_content"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["change_type"], name: "index_panda_cms_pro_content_changes_on_change_type"
    t.index ["panda_cms_pro_content_version_id"], name: "index_pro_content_changes_on_version"
  end

  create_table "panda_cms_pro_content_comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "commentable_type", null: false
    t.uuid "commentable_id", null: false
    t.uuid "user_id", null: false
    t.string "section_identifier"
    t.text "content", null: false
    t.uuid "parent_id"
    t.boolean "resolved", default: false, null: false
    t.uuid "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_pro_content_comments_on_commentable"
    t.index ["parent_id"], name: "index_panda_cms_pro_content_comments_on_parent_id"
    t.index ["resolved"], name: "index_panda_cms_pro_content_comments_on_resolved"
    t.index ["user_id"], name: "index_panda_cms_pro_content_comments_on_user_id"
  end

  create_table "panda_cms_pro_content_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "domain", null: false
    t.enum "trust_level", default: "neutral", null: false, enum_type: "panda_cms_pro_source_trust_level"
    t.string "default_callout_type"
    t.text "notes"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_panda_cms_pro_content_sources_on_domain", unique: true
    t.index ["trust_level"], name: "index_panda_cms_pro_content_sources_on_trust_level"
  end

  create_table "panda_cms_pro_content_suggestions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "suggestable_type", null: false
    t.uuid "suggestable_id", null: false
    t.uuid "user_id", null: false
    t.string "section_identifier"
    t.enum "suggestion_type", null: false, enum_type: "panda_cms_pro_suggestion_type"
    t.enum "status", default: "pending", null: false, enum_type: "panda_cms_pro_suggestion_status"
    t.text "content", null: false
    t.text "rationale"
    t.jsonb "metadata", default: {}
    t.uuid "reviewed_by_id"
    t.datetime "reviewed_at"
    t.text "admin_notes"
    t.boolean "requires_specialist_review", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_panda_cms_pro_content_suggestions_on_created_at"
    t.index ["reviewed_by_id"], name: "index_panda_cms_pro_content_suggestions_on_reviewed_by_id"
    t.index ["status"], name: "index_panda_cms_pro_content_suggestions_on_status"
    t.index ["suggestable_type", "suggestable_id"], name: "index_pro_content_suggestions_on_suggestable"
    t.index ["suggestion_type"], name: "index_panda_cms_pro_content_suggestions_on_suggestion_type"
    t.index ["user_id"], name: "index_panda_cms_pro_content_suggestions_on_user_id"
  end

  create_table "panda_cms_pro_content_sync_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "sync_type", null: false, enum_type: "panda_cms_pro_sync_type"
    t.enum "status", default: "pending", null: false, enum_type: "panda_cms_pro_sync_status"
    t.uuid "user_id", null: false
    t.jsonb "items_synced", default: [], null: false
    t.jsonb "summary", default: {}
    t.text "error_log"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "source_environment"
    t.string "destination_environment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_panda_cms_pro_content_sync_logs_on_created_at"
    t.index ["status"], name: "index_panda_cms_pro_content_sync_logs_on_status"
    t.index ["sync_type"], name: "index_panda_cms_pro_content_sync_logs_on_sync_type"
    t.index ["user_id"], name: "index_panda_cms_pro_content_sync_logs_on_user_id"
  end

  create_table "panda_cms_pro_content_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "versionable_type", null: false
    t.uuid "versionable_id", null: false
    t.integer "version_number", default: 1, null: false
    t.jsonb "content", null: false
    t.text "change_summary"
    t.uuid "user_id"
    t.string "source", default: "manual"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_panda_cms_pro_content_versions_on_created_at"
    t.index ["user_id"], name: "index_panda_cms_pro_content_versions_on_user_id"
    t.index ["version_number"], name: "index_panda_cms_pro_content_versions_on_version_number"
    t.index ["versionable_type", "versionable_id"], name: "index_pro_content_versions_on_versionable"
  end

  create_table "panda_cms_pro_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.jsonb "permissions", default: {}, null: false
    t.jsonb "custom_metadata", default: {}
    t.boolean "system_role", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_panda_cms_pro_roles_on_name", unique: true
  end

  create_table "panda_cms_pro_user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "panda_cms_pro_role_id", null: false
    t.datetime "expires_at"
    t.string "access_token"
    t.datetime "access_token_expires_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_panda_cms_pro_user_roles_on_access_token", unique: true
    t.index ["panda_cms_pro_role_id"], name: "index_panda_cms_pro_user_roles_on_panda_cms_pro_role_id"
    t.index ["user_id", "panda_cms_pro_role_id"], name: "index_unique_user_role_pro", unique: true
    t.index ["user_id"], name: "index_panda_cms_pro_user_roles_on_user_id"
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
  end

  create_table "panda_cms_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "file_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_uses"
    t.integer "pages_count", default: 0
  end

  create_table "panda_cms_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "firstname"
    t.string "lastname"
    t.string "email"
    t.string "image_url"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_theme", default: "default"
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
    t.string "firstname", null: false
    t.string "lastname", null: false
    t.string "email", null: false
    t.string "image_url"
    t.boolean "admin", default: false, null: false
    t.string "current_theme", default: "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  add_foreign_key "panda_cms_pro_collection_fields", "panda_cms_pro_collections", column: "collection_id"
  add_foreign_key "panda_cms_pro_collection_items", "panda_cms_pro_collections", column: "collection_id"
  add_foreign_key "panda_cms_pro_content_changes", "panda_cms_pro_content_versions"
  add_foreign_key "panda_cms_pro_content_comments", "panda_cms_pro_content_comments", column: "parent_id"
  add_foreign_key "panda_cms_pro_content_comments", "panda_core_users", column: "resolved_by_id"
  add_foreign_key "panda_cms_pro_content_comments", "panda_core_users", column: "user_id"
  add_foreign_key "panda_cms_pro_content_suggestions", "panda_core_users", column: "reviewed_by_id"
  add_foreign_key "panda_cms_pro_content_suggestions", "panda_core_users", column: "user_id"
  add_foreign_key "panda_cms_pro_content_sync_logs", "panda_core_users", column: "user_id"
  add_foreign_key "panda_cms_pro_content_versions", "panda_core_users", column: "user_id"
  add_foreign_key "panda_cms_pro_user_roles", "panda_cms_pro_roles"
  add_foreign_key "panda_cms_pro_user_roles", "panda_core_users", column: "user_id"
  add_foreign_key "panda_cms_redirects", "panda_cms_pages", column: "destination_panda_cms_page_id"
  add_foreign_key "panda_cms_redirects", "panda_cms_pages", column: "origin_panda_cms_page_id"
  add_foreign_key "panda_cms_visits", "panda_cms_pages", column: "page_id"
  add_foreign_key "panda_cms_visits", "panda_cms_redirects", column: "redirect_id"
  add_foreign_key "panda_cms_visits", "panda_core_users", column: "user_id"
end
