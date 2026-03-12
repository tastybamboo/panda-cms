# frozen_string_literal: true

# This migration comes from panda_core (originally 20260310000001)
class CreatePandaCoreTags < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_core_tags, id: :uuid do |t|
      t.string :tenant_type
      t.bigint :tenant_id
      t.string :name, null: false
      t.string :colour
      t.integer :taggings_count, default: 0, null: false
      t.timestamps

      t.index [:tenant_type, :tenant_id]
      t.index [:tenant_type, :tenant_id, :name], unique: true, name: :idx_panda_core_tags_on_tenant_and_name
    end

    create_table :panda_core_taggings, id: :uuid do |t|
      t.references :tag, null: false, type: :uuid, foreign_key: {to_table: :panda_core_tags}
      t.string :taggable_type, null: false
      t.string :taggable_id, null: false
      t.timestamps

      t.index [:taggable_type, :taggable_id], name: :idx_panda_core_taggings_on_taggable
      t.index [:tag_id, :taggable_type, :taggable_id], unique: true, name: :idx_panda_core_taggings_unique
    end
  end
end
