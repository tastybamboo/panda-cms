# frozen_string_literal: true

# Enforce global path uniqueness at the database level for non-archived pages.
#
# Previously, the model validation only checked uniqueness within the same
# parent, allowing duplicate pages at the same URL path with different parents.
# Since the path is the URL and PagesController uses find_by(path:), duplicates
# caused unpredictable page serving.
class AddUniqueIndexOnPagePath < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicates before adding the constraint.
    # Keep the page with the most children (most likely the "real" one);
    # break ties by earliest created_at.
    execute <<~SQL
      DELETE FROM panda_cms_block_contents
      WHERE panda_cms_page_id IN (
        SELECT id FROM panda_cms_pages
        WHERE id NOT IN (
          SELECT DISTINCT ON (path) id
          FROM panda_cms_pages
          WHERE status != 'archived'
          ORDER BY path, children_count DESC, created_at ASC
        )
        AND status != 'archived'
      )
    SQL

    execute <<~SQL
      DELETE FROM panda_cms_pages
      WHERE id NOT IN (
        SELECT DISTINCT ON (path) id
        FROM panda_cms_pages
        WHERE status != 'archived'
        ORDER BY path, children_count DESC, created_at ASC
      )
      AND status != 'archived'
    SQL

    # Replace the non-unique index with a partial unique index
    remove_index :panda_cms_pages, name: "index_panda_cms_pages_on_path"
    add_index :panda_cms_pages, :path,
      unique: true,
      where: "status != 'archived'",
      name: "index_panda_cms_pages_on_path_unique_non_archived"
  end

  def down
    remove_index :panda_cms_pages, name: "index_panda_cms_pages_on_path_unique_non_archived"
    add_index :panda_cms_pages, :path, name: "index_panda_cms_pages_on_path"
  end
end
