# This migration comes from panda_cms (originally 20241120000419)
class RemovePostTagReferences < ActiveRecord::Migration[8.0]
  def up
    remove_reference :panda_cms_posts, :post_tag, foreign_key: {to_table: :panda_cms_post_tags}, type: :uuid
    drop_table :panda_cms_post_tags
  end

  def down
    create_table :panda_cms_post_tags, id: :uuid do |t|
      t.string :tag
      t.string :description
      t.string :slug
      t.timestamps
      t.index :tag, unique: true
      t.index :slug, unique: true
    end

    add_reference :panda_cms_posts, :post_tag, type: :uuid, foreign_key: {to_table: :panda_cms_post_tags}
  end
end
