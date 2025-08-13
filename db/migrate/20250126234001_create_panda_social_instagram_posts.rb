# frozen_string_literal: true

class CreatePandaSocialInstagramPosts < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:panda_social_instagram_posts)

    create_table :panda_social_instagram_posts, id: :uuid do |t|
      t.string :instagram_id, null: false
      t.text :caption
      t.datetime :posted_at, null: false
      t.string :permalink
      t.timestamps

      t.index :instagram_id, unique: true
      t.index :posted_at
    end
  end
end
