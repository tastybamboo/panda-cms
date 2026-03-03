# frozen_string_literal: true

class CreatePandaCMSPostCategories < ActiveRecord::Migration[8.1]
  def up
    create_table :panda_cms_post_categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.timestamps
    end

    add_index :panda_cms_post_categories, :name, unique: true
    add_index :panda_cms_post_categories, :slug, unique: true

    # Add nullable FK column first
    add_reference :panda_cms_posts, :post_category, type: :uuid, foreign_key: {to_table: :panda_cms_post_categories}, null: true

    # Seed default category and backfill
    general = execute(<<~SQL).first
      INSERT INTO panda_cms_post_categories (id, name, slug, created_at, updated_at)
      VALUES (gen_random_uuid(), 'General', 'general', NOW(), NOW())
      RETURNING id
    SQL

    execute(<<~SQL)
      UPDATE panda_cms_posts SET post_category_id = '#{general["id"]}' WHERE post_category_id IS NULL
    SQL

    # Now make the column NOT NULL
    change_column_null :panda_cms_posts, :post_category_id, false
  end

  def down
    change_column_null :panda_cms_posts, :post_category_id, true
    remove_reference :panda_cms_posts, :post_category
    drop_table :panda_cms_post_categories
  end
end
