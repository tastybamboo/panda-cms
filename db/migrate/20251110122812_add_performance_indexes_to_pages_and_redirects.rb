# frozen_string_literal: true

class AddPerformanceIndexesToPagesAndRedirects < ActiveRecord::Migration[8.0]
  def change
    # Add index to pages.path for fast page lookups
    # This is the most critical query path in the CMS
    add_index :panda_cms_pages, :path, name: "index_panda_cms_pages_on_path"

    # Add index to redirects.origin_path for fast redirect lookups
    # Checked on every request in PagesController#handle_redirects
    add_index :panda_cms_redirects, :origin_path, name: "index_panda_cms_redirects_on_origin_path"
  end
end
