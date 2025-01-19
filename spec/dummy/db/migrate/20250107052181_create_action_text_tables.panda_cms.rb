# This migration comes from panda_cms (originally 20240904200605)
# This migration comes from action_text (originally 20180528164100)
class CreateActionTextTables < ActiveRecord::Migration[7.2]
  def change
    create_table :action_text_rich_texts, id: :uuid do |t|
      t.string :name, null: false
      t.text :body, limit: 16.megabytes - 1
      t.references :record, null: false, polymorphic: true, index: false, type: :uuid
      t.timestamps
      t.index [:record_type, :record_id, :name], name: "index_action_text_rich_texts_uniqueness", unique: true
    end

    create_table :action_text_rich_text_versions, id: :uuid do |t|
      t.string :item_type, null: false
      t.string :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.jsonb :object
      t.jsonb :object_changes
      t.datetime :created_at
    end

    add_index :action_text_rich_text_versions, %i[item_type item_id]
  end
end
