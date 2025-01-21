# This migration comes from panda_cms (originally 20241123234140)
class RemovePostTagIdFromPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :panda_cms_posts, :post_tag_id
  end
end
