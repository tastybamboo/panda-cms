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

ActiveRecord::Schema[8.1].define(version: 2026_02_07_112500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "panda_cms_block_kind", ["plain_text", "rich_text", "image", "video", "audio", "file", "code", "iframe", "quote", "list", "table", "form"]
  create_enum "panda_cms_menu_kind", ["static", "auto"]
  create_enum "panda_cms_menu_ordering", ["default", "alphabetical"]
  create_enum "panda_cms_og_type", ["website", "article", "profile", "video", "book"]
  create_enum "panda_cms_page_status", ["active", "draft", "hidden", "archived", "pending_review"]
  create_enum "panda_cms_post_status", ["active", "draft", "hidden", "archived", "pending_review"]
  create_enum "panda_cms_pro_content_change_type", ["addition", "deletion", "modification", "callout", "citation"]
  create_enum "panda_cms_pro_source_trust_level", ["always_prefer", "trusted", "neutral", "untrusted", "never_use"]
  create_enum "panda_cms_pro_suggestion_status", ["pending", "specialist_review", "admin_review", "approved", "rejected"]
  create_enum "panda_cms_pro_suggestion_type", ["edit", "addition", "deletion", "comment", "citation"]
  create_enum "panda_cms_pro_sync_status", ["pending", "in_progress", "completed", "failed", "rolled_back"]
  create_enum "panda_cms_pro_sync_type", ["push", "pull"]
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
    t.index ["panda_cms_menu_id", "lft", "rgt"], name: "index_menu_items_on_menu_id_and_nested_set"
    t.index ["panda_cms_menu_id"], name: "index_panda_cms_menu_items_on_panda_cms_menu_id"
    t.index ["panda_cms_page_id"], name: "index_panda_cms_menu_items_on_panda_cms_page_id"
    t.index ["rgt"], name: "index_panda_cms_menu_items_on_rgt"
  end

  create_table "panda_cms_menus", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depth"
    t.enum "kind", default: "static", null: false, enum_type: "panda_cms_menu_kind"
    t.string "name", null: false
    t.enum "ordering", default: "default", null: false, enum_type: "panda_cms_menu_ordering"
    t.uuid "start_page_id"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_panda_cms_menus_on_name", unique: true
    t.index ["start_page_id"], name: "index_panda_cms_menus_on_start_page_id"
  end

  create_table "panda_cms_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "cached_last_updated_at"
    t.string "canonical_url"
    t.integer "children_count", default: 0, null: false
    t.integer "contributor_count", default: 0
    t.datetime "created_at", null: false
    t.integer "depth"
    t.boolean "inherit_seo", default: true, null: false
    t.datetime "last_contributed_at"
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
    t.string "workflow_status", default: "draft"
    t.index ["cached_last_updated_at"], name: "index_panda_cms_pages_on_cached_last_updated_at"
    t.index ["last_contributed_at"], name: "index_panda_cms_pages_on_last_contributed_at"
    t.index ["lft", "rgt"], name: "index_pages_on_nested_set"
    t.index ["lft"], name: "index_panda_cms_pages_on_lft"
    t.index ["page_type"], name: "index_panda_cms_pages_on_page_type"
    t.index ["panda_cms_template_id"], name: "index_panda_cms_pages_on_panda_cms_template_id"
    t.index ["parent_id", "lft"], name: "index_pages_on_parent_and_lft"
    t.index ["parent_id"], name: "index_panda_cms_pages_on_parent_id"
    t.index ["path"], name: "index_panda_cms_pages_on_path"
    t.index ["rgt"], name: "index_panda_cms_pages_on_rgt"
    t.index ["status"], name: "index_panda_cms_pages_on_status"
    t.index ["workflow_status"], name: "index_panda_cms_pages_on_workflow_status"
  end

  create_table "panda_cms_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id"
    t.text "cached_content"
    t.string "canonical_url"
    t.jsonb "content", default: {}, null: false
    t.integer "contributor_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "last_contributed_at"
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
    t.string "workflow_status", default: "draft"
    t.index ["author_id"], name: "index_panda_cms_posts_on_author_id"
    t.index ["last_contributed_at"], name: "index_panda_cms_posts_on_last_contributed_at"
    t.index ["slug"], name: "index_panda_cms_posts_on_slug", unique: true
    t.index ["status"], name: "index_panda_cms_posts_on_status"
    t.index ["user_id"], name: "index_panda_cms_posts_on_user_id"
    t.index ["workflow_status"], name: "index_panda_cms_posts_on_workflow_status"
  end

  create_table "panda_cms_pro_collection_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "collection_id", null: false
    t.datetime "created_at", null: false
    t.string "field_type", null: false
    t.text "instructions"
    t.string "key", null: false
    t.string "label", null: false
    t.integer "position", default: 0, null: false
    t.boolean "required", default: false, null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "key"], name: "idx_panda_cms_pro_collection_fields_keys", unique: true
    t.index ["collection_id"], name: "index_panda_cms_pro_collection_fields_on_collection_id"
  end

  create_table "panda_cms_pro_collection_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "collection_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "position"
    t.datetime "published_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["collection_id", "position"], name: "idx_panda_cms_pro_collection_items_position"
    t.index ["collection_id"], name: "index_panda_cms_pro_collection_items_on_collection_id"
  end

  create_table "panda_cms_pro_collections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "item_label"
    t.integer "items_count", default: 0, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_panda_cms_pro_collections_on_slug", unique: true
  end

  create_table "panda_cms_pro_content_changes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "change_type", null: false, enum_type: "panda_cms_pro_content_change_type"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.text "new_content"
    t.text "old_content"
    t.uuid "panda_cms_pro_content_version_id", null: false
    t.string "section_identifier"
    t.datetime "updated_at", null: false
    t.index ["change_type"], name: "index_panda_cms_pro_content_changes_on_change_type"
    t.index ["panda_cms_pro_content_version_id"], name: "index_pro_content_changes_on_version"
  end

  create_table "panda_cms_pro_content_comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "commentable_id", null: false
    t.string "commentable_type", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.uuid "parent_id"
    t.boolean "resolved", default: false, null: false
    t.datetime "resolved_at"
    t.uuid "resolved_by_id"
    t.string "section_identifier"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_pro_content_comments_on_commentable"
    t.index ["parent_id"], name: "index_panda_cms_pro_content_comments_on_parent_id"
    t.index ["resolved"], name: "index_panda_cms_pro_content_comments_on_resolved"
    t.index ["user_id"], name: "index_panda_cms_pro_content_comments_on_user_id"
  end

  create_table "panda_cms_pro_content_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_callout_type"
    t.string "domain", null: false
    t.jsonb "metadata", default: {}
    t.text "notes"
    t.enum "trust_level", default: "neutral", null: false, enum_type: "panda_cms_pro_source_trust_level"
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_panda_cms_pro_content_sources_on_domain", unique: true
    t.index ["trust_level"], name: "index_panda_cms_pro_content_sources_on_trust_level"
  end

  create_table "panda_cms_pro_content_suggestions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "admin_notes"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.text "rationale"
    t.boolean "requires_specialist_review", default: false
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_id"
    t.string "section_identifier"
    t.enum "status", default: "pending", null: false, enum_type: "panda_cms_pro_suggestion_status"
    t.uuid "suggestable_id", null: false
    t.string "suggestable_type", null: false
    t.enum "suggestion_type", null: false, enum_type: "panda_cms_pro_suggestion_type"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_panda_cms_pro_content_suggestions_on_created_at"
    t.index ["reviewed_by_id"], name: "index_panda_cms_pro_content_suggestions_on_reviewed_by_id"
    t.index ["status"], name: "index_panda_cms_pro_content_suggestions_on_status"
    t.index ["suggestable_type", "suggestable_id"], name: "index_pro_content_suggestions_on_suggestable"
    t.index ["suggestion_type"], name: "index_panda_cms_pro_content_suggestions_on_suggestion_type"
    t.index ["user_id"], name: "index_panda_cms_pro_content_suggestions_on_user_id"
  end

  create_table "panda_cms_pro_content_sync_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "destination_environment"
    t.text "error_log"
    t.jsonb "items_synced", default: [], null: false
    t.string "source_environment"
    t.datetime "started_at"
    t.enum "status", default: "pending", null: false, enum_type: "panda_cms_pro_sync_status"
    t.jsonb "summary", default: {}
    t.enum "sync_type", null: false, enum_type: "panda_cms_pro_sync_type"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["created_at"], name: "index_panda_cms_pro_content_sync_logs_on_created_at"
    t.index ["status"], name: "index_panda_cms_pro_content_sync_logs_on_status"
    t.index ["sync_type"], name: "index_panda_cms_pro_content_sync_logs_on_sync_type"
    t.index ["user_id"], name: "index_panda_cms_pro_content_sync_logs_on_user_id"
  end

  create_table "panda_cms_pro_content_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "change_summary"
    t.jsonb "content", null: false
    t.datetime "created_at", null: false
    t.string "source", default: "manual"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.integer "version_number", null: false
    t.uuid "versionable_id", null: false
    t.string "versionable_type", null: false
    t.index ["created_at"], name: "index_panda_cms_pro_content_versions_on_created_at"
    t.index ["user_id"], name: "index_panda_cms_pro_content_versions_on_user_id"
    t.index ["version_number"], name: "index_panda_cms_pro_content_versions_on_version_number"
    t.index ["versionable_type", "versionable_id"], name: "index_pro_content_versions_on_versionable"
  end

  create_table "panda_cms_pro_page_presences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.uuid "page_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["last_seen_at"], name: "index_panda_cms_pro_page_presences_on_last_seen_at"
    t.index ["page_id", "user_id"], name: "index_unique_page_presence", unique: true
  end

  create_table "panda_cms_pro_provider_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.uuid "configurable_id"
    t.string "configurable_type"
    t.datetime "created_at", null: false
    t.text "key"
    t.integer "priority", default: 0, null: false
    t.string "provider_name", null: false
    t.string "provider_type", null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["configurable_type", "configurable_id", "provider_type"], name: "index_provider_configs_on_configurable_and_type"
    t.index ["priority"], name: "index_provider_configs_on_priority"
    t.index ["provider_type", "active"], name: "index_provider_configs_on_type_and_active"
  end

  create_table "panda_cms_pro_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_metadata", default: {}
    t.string "description"
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.boolean "system_role", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_panda_cms_pro_roles_on_name", unique: true
  end

  create_table "panda_cms_pro_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "encrypted_value"
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", default: {}, null: false
    t.index ["key"], name: "index_panda_cms_pro_settings_on_key", unique: true
  end

  create_table "panda_cms_pro_user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token"
    t.datetime "access_token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.jsonb "metadata", default: {}
    t.uuid "panda_cms_pro_role_id", null: false
    t.jsonb "scoped_permissions"
    t.string "token_name"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0, null: false
    t.uuid "user_id", null: false
    t.index ["access_token"], name: "index_panda_cms_pro_user_roles_on_access_token", unique: true
    t.index ["panda_cms_pro_role_id"], name: "index_panda_cms_pro_user_roles_on_panda_cms_pro_role_id"
    t.index ["user_id", "panda_cms_pro_role_id"], name: "index_unique_user_role_pro", unique: true
    t.index ["user_id"], name: "index_panda_cms_pro_user_roles_on_user_id"
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

  create_table "panda_core_file_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.uuid "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_panda_core_file_categories_on_parent_id"
    t.index ["position"], name: "index_panda_core_file_categories_on_position"
    t.index ["slug"], name: "index_panda_core_file_categories_on_slug", unique: true
  end

  create_table "panda_core_file_categorizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.uuid "file_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["blob_id"], name: "index_panda_core_file_categorizations_on_blob_id"
    t.index ["file_category_id", "blob_id"], name: "idx_file_categorizations_on_category_and_blob", unique: true
    t.index ["file_category_id"], name: "index_panda_core_file_categorizations_on_file_category_id"
  end

  create_table "panda_core_presences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.uuid "presenceable_id", null: false
    t.string "presenceable_type", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["last_seen_at"], name: "index_panda_core_presences_on_last_seen_at"
    t.index ["presenceable_type", "presenceable_id", "user_id"], name: "index_unique_presence", unique: true
    t.index ["presenceable_type", "presenceable_id"], name: "index_presences_on_presenceable"
  end

  create_table "panda_core_user_activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.uuid "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["action"], name: "index_panda_core_user_activities_on_action"
    t.index ["created_at"], name: "index_panda_core_user_activities_on_created_at"
    t.index ["resource_type", "resource_id"], name: "idx_on_resource_type_resource_id_fe067c2837"
    t.index ["user_id"], name: "index_panda_core_user_activities_on_user_id"
  end

  create_table "panda_core_user_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.datetime "revoked_at"
    t.uuid "revoked_by_id"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["active"], name: "index_panda_core_user_sessions_on_active"
    t.index ["session_id"], name: "index_panda_core_user_sessions_on_session_id", unique: true
    t.index ["user_id"], name: "index_panda_core_user_sessions_on_user_id"
  end

  create_table "panda_core_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "current_theme"
    t.string "email", null: false
    t.boolean "enabled", default: true, null: false
    t.string "image_url"
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.uuid "invited_by_id"
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.integer "login_count", default: 0, null: false
    t.string "name"
    t.string "oauth_avatar_url"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_panda_core_users_on_email", unique: true
    t.index ["enabled"], name: "index_panda_core_users_on_enabled"
    t.index ["invitation_token"], name: "index_panda_core_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_panda_core_users_on_invited_by_id"
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
  add_foreign_key "panda_cms_pro_collection_fields", "panda_cms_pro_collections", column: "collection_id"
  add_foreign_key "panda_cms_pro_collection_items", "panda_cms_pro_collections", column: "collection_id"
  add_foreign_key "panda_cms_pro_content_changes", "panda_cms_pro_content_versions"
  add_foreign_key "panda_cms_pro_content_comments", "panda_cms_pro_content_comments", column: "parent_id"
  add_foreign_key "panda_cms_pro_user_roles", "panda_cms_pro_roles"
  add_foreign_key "panda_cms_redirects", "panda_cms_pages", column: "destination_panda_cms_page_id"
  add_foreign_key "panda_cms_redirects", "panda_cms_pages", column: "origin_panda_cms_page_id"
  add_foreign_key "panda_cms_visits", "panda_cms_pages", column: "page_id"
  add_foreign_key "panda_cms_visits", "panda_cms_redirects", column: "redirect_id"
  add_foreign_key "panda_cms_visits", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_file_categories", "panda_core_file_categories", column: "parent_id"
  add_foreign_key "panda_core_file_categorizations", "active_storage_blobs", column: "blob_id"
  add_foreign_key "panda_core_file_categorizations", "panda_core_file_categories", column: "file_category_id"
  add_foreign_key "panda_core_presences", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_user_activities", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_user_sessions", "panda_core_users", column: "revoked_by_id", on_delete: :nullify
  add_foreign_key "panda_core_user_sessions", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_users", "panda_core_users", column: "invited_by_id"
end
