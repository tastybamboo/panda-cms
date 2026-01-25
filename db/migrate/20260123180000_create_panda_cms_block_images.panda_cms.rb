# frozen_string_literal: true

class CreatePandaCmsBlockImages < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_cms_block_images, id: :uuid do |t|
      t.references :panda_cms_block_content,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :panda_cms_block_contents}

      t.integer :position, null: false, default: 0
      t.string :key
      t.string :alt_text
      t.text :caption
      t.string :link_url
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :panda_cms_block_images,
      [:panda_cms_block_content_id, :position],
      name: "index_panda_cms_block_images_on_content_id_and_position"

    add_index :panda_cms_block_images,
      [:panda_cms_block_content_id, :key],
      unique: true,
      where: "key IS NOT NULL",
      name: "index_panda_cms_block_images_on_content_id_and_key"
  end
end
