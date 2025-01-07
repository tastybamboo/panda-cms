# This migration comes from panda_cms (originally 20241119214549)
class RemoveActionTextFromPosts < ActiveRecord::Migration[7.1]
  def up
    if column_exists?(:panda_cms_posts, :post_content)
      remove_column :panda_cms_posts, :post_content
    end
  end

  def down
    unless column_exists?(:panda_cms_posts, :post_content)
      add_column :panda_cms_posts, :post_content, :text
    end
  end
end
