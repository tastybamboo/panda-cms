# frozen_string_literal: true

class CreatePandaCMSPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_post_tags, id: :uuid do |t|
      t.string :tag
      t.string :description
      t.string :slug
      t.timestamps
      t.index :tag, unique: true
      t.index :slug, unique: true
    end

    create_table :panda_cms_posts, id: :uuid do |t|
      t.string :title
      t.string :slug
      t.text :content
      t.datetime :published_at
      t.references :post_tag, type: :uuid, null: false, foreign_key: {to_table: :panda_cms_post_tags}
      t.references :user, type: :uuid, null: false, foreign_key: {to_table: :panda_core_users}
      t.timestamps
      t.index :slug, unique: true
    end

    create_enum :panda_cms_post_status, %w[active draft hidden archived]
    add_column :panda_cms_posts, :status, :panda_cms_post_status, default: "draft", null: false
    add_index :panda_cms_posts, :status
  end
end
