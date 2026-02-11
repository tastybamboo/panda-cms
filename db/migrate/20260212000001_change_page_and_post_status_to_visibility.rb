# frozen_string_literal: true

class ChangePageAndPostStatusToVisibility < ActiveRecord::Migration[7.2]
  def up
    # 1. Save current values to a temp string column
    add_column :panda_cms_pages, :status_tmp, :string
    add_column :panda_cms_posts, :status_tmp, :string
    execute "UPDATE panda_cms_pages SET status_tmp = status::text"
    execute "UPDATE panda_cms_posts SET status_tmp = status::text"

    # 2. Drop the old enum columns and types
    remove_column :panda_cms_pages, :status
    remove_column :panda_cms_posts, :status
    execute "DROP TYPE panda_cms_page_status"
    execute "DROP TYPE panda_cms_post_status"

    # 3. Create new enum types with only valid values
    create_enum "panda_cms_page_status", ["published", "unlisted", "hidden", "archived"]
    create_enum "panda_cms_post_status", ["published", "unlisted", "hidden", "archived"]

    # 4. Add columns back with new enum type
    add_column :panda_cms_pages, :status, :enum,
      enum_type: "panda_cms_page_status", default: "published", null: false
    add_column :panda_cms_posts, :status, :enum,
      enum_type: "panda_cms_post_status", default: "published", null: false

    # 5. Map old values to new values
    # active → published, draft/pending_review → published (workflow is now version-level)
    # hidden stays hidden, archived stays archived
    execute <<~SQL
      UPDATE panda_cms_pages SET status = CASE status_tmp
        WHEN 'active' THEN 'published'
        WHEN 'draft' THEN 'published'
        WHEN 'pending_review' THEN 'published'
        WHEN 'hidden' THEN 'hidden'
        WHEN 'archived' THEN 'archived'
        ELSE 'published'
      END::panda_cms_page_status
    SQL
    execute <<~SQL
      UPDATE panda_cms_posts SET status = CASE status_tmp
        WHEN 'active' THEN 'published'
        WHEN 'draft' THEN 'published'
        WHEN 'pending_review' THEN 'published'
        WHEN 'hidden' THEN 'hidden'
        WHEN 'archived' THEN 'archived'
        ELSE 'published'
      END::panda_cms_post_status
    SQL

    # 6. Drop temp columns
    remove_column :panda_cms_pages, :status_tmp
    remove_column :panda_cms_posts, :status_tmp
  end

  def down
    # 1. Save current values to a temp string column
    add_column :panda_cms_pages, :status_tmp, :string
    add_column :panda_cms_posts, :status_tmp, :string
    execute "UPDATE panda_cms_pages SET status_tmp = status::text"
    execute "UPDATE panda_cms_posts SET status_tmp = status::text"

    # 2. Drop the new enum columns and types
    remove_column :panda_cms_pages, :status
    remove_column :panda_cms_posts, :status
    execute "DROP TYPE panda_cms_page_status"
    execute "DROP TYPE panda_cms_post_status"

    # 3. Recreate original enum types
    create_enum "panda_cms_page_status", ["active", "draft", "pending_review", "hidden", "archived"]
    create_enum "panda_cms_post_status", ["active", "draft", "pending_review", "hidden", "archived"]

    # 4. Add columns back with original enum type
    add_column :panda_cms_pages, :status, :enum,
      enum_type: "panda_cms_page_status", default: "active", null: false
    add_column :panda_cms_posts, :status, :enum,
      enum_type: "panda_cms_post_status", default: "active", null: false

    # 5. Map new values back to old values
    # published → active, unlisted → active (no equivalent in old schema)
    execute <<~SQL
      UPDATE panda_cms_pages SET status = CASE status_tmp
        WHEN 'published' THEN 'active'
        WHEN 'unlisted' THEN 'active'
        WHEN 'hidden' THEN 'hidden'
        WHEN 'archived' THEN 'archived'
        ELSE 'active'
      END::panda_cms_page_status
    SQL
    execute <<~SQL
      UPDATE panda_cms_posts SET status = CASE status_tmp
        WHEN 'published' THEN 'active'
        WHEN 'unlisted' THEN 'active'
        WHEN 'hidden' THEN 'hidden'
        WHEN 'archived' THEN 'archived'
        ELSE 'active'
      END::panda_cms_post_status
    SQL

    # 6. Drop temp columns
    remove_column :panda_cms_pages, :status_tmp
    remove_column :panda_cms_posts, :status_tmp
  end
end
