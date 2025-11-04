class AddCachedLastUpdatedAtToPandaCMSPages < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_pages, :cached_last_updated_at, :datetime
    add_index :panda_cms_pages, :cached_last_updated_at

    # Backfill existing pages
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE panda_cms_pages
          SET cached_last_updated_at = GREATEST(
            updated_at,
            COALESCE(
              (SELECT MAX(updated_at) FROM panda_cms_block_contents WHERE panda_cms_page_id = panda_cms_pages.id),
              updated_at
            )
          )
        SQL
      end
    end
  end
end
