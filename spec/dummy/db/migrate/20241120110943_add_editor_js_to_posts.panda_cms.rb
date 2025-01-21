# This migration comes from panda_cms (originally 20241120110943)
class AddEditorJsToPosts < ActiveRecord::Migration[7.0]
  def up
    # First, add a temporary column
    add_column :panda_cms_posts, :content_jsonb, :jsonb, default: {}, null: false

    # Copy data from the old column to the new one, converting to JSONB
    execute <<-SQL
      UPDATE panda_cms_posts
      SET content_jsonb =
        CASE
          WHEN content IS NULL THEN '{}'::jsonb
          WHEN content::text = '' THEN '{}'::jsonb
          ELSE content::jsonb
        END;
    SQL

    # Remove the old column
    remove_column :panda_cms_posts, :content

    # Rename the new column to the original name
    rename_column :panda_cms_posts, :content_jsonb, :content
  end

  def down
    change_column :panda_cms_posts, :content, :text
  end
end
