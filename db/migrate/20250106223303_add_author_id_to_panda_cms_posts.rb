# frozen_string_literal: true

class AddAuthorIdToPandaCMSPosts < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:panda_cms_posts, :author_id)
      add_reference :panda_cms_posts, :author, type: :uuid, foreign_key: {to_table: :panda_core_users}
    end
  end
end
