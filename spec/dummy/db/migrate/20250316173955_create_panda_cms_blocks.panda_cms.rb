# This migration comes from panda_cms (originally 20240303022441)
class CreatePandaCMSBlocks < ActiveRecord::Migration[7.1]
  def change
    create_enum :panda_cms_block_kind, ["plain_text", "rich_text", "image", "video", "audio", "file", "code", "iframe", "quote", "list", "table", "form"]

    create_table :panda_cms_blocks, id: :uuid do |t|
      t.enum :kind, enum_type: :panda_cms_block_kind, default: "plain_text", null: false
      t.string :name
      t.string :key
      t.references :panda_cms_template, type: :uuid, foreign_key: {to_table: :panda_cms_templates}, null: false
      t.timestamps
    end
  end
end
