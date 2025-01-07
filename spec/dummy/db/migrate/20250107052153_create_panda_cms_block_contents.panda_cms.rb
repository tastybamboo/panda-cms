# This migration comes from panda_cms (originally 20240303024256)
class CreatePandaCMSBlockContents < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_block_contents, id: :uuid do |t|
      t.references :panda_cms_page, null: false, foreign_key: true, type: :uuid
      t.references :panda_cms_block, null: false, foreign_key: true, type: :uuid
      t.jsonb :content, null: false, default: {}
      t.timestamps
    end
  end
end
