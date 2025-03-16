# This migration comes from panda_cms (originally 20241120113859)
class AddCachedContentToPandaCMSPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_posts, :cached_content, :text
  end
end
