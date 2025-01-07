class AddAuthorIdToPandaCMSPosts < ActiveRecord::Migration[8.0]
  def change
    add_reference :panda_cms_posts, :author, type: :uuid, foreign_key: {to_table: :panda_cms_users}
  end
end
