# frozen_string_literal: true

class AddCachedContentToPandaCMSPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_posts, :cached_content, :text
  end
end
