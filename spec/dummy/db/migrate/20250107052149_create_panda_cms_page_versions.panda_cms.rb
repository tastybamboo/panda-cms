# This migration comes from panda_cms (originally 20240219213327)
class CreatePandaCMSPageVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_page_versions, id: :uuid do |t|
      t.string :item_type, null: false
      t.string :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.jsonb :object
      t.jsonb :object_changes
      t.datetime :created_at
    end
    add_index :panda_cms_page_versions, %i[item_type item_id]
  end
end
