class SetPageTypesForExistingPages < ActiveRecord::Migration[8.0]
  def up
    # Set system type for error pages
    execute <<-SQL
      UPDATE panda_cms_pages
      SET page_type = 'system'
      WHERE path IN ('/404', '/500')
    SQL

    # Set posts type for news/blog pages
    execute <<-SQL
      UPDATE panda_cms_pages
      SET page_type = 'posts'
      WHERE path LIKE '%news%' OR path LIKE '%blog%' OR path LIKE '%updates%'
    SQL

    # All other pages remain as 'standard' (the default)
  end

  def down
    # Reset all to standard
    execute <<-SQL
      UPDATE panda_cms_pages
      SET page_type = 'standard'
    SQL
  end
end
