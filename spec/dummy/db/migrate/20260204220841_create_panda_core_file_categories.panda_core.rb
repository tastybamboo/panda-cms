# frozen_string_literal: true

# This migration comes from panda_core (originally 20260202171614)
class CreatePandaCoreFileCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_core_file_categories, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :parent, type: :uuid, foreign_key: {to_table: :panda_core_file_categories}
      t.boolean :system, null: false, default: false
      t.string :icon
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :panda_core_file_categories, :slug, unique: true
    add_index :panda_core_file_categories, :position

    create_table :panda_core_file_categorizations, id: :uuid do |t|
      t.references :file_category, null: false, type: :uuid,
        foreign_key: {to_table: :panda_core_file_categories}
      t.bigint :blob_id, null: false
      t.timestamps
    end

    add_index :panda_core_file_categorizations, %i[file_category_id blob_id],
      unique: true, name: :idx_file_categorizations_on_category_and_blob
    add_index :panda_core_file_categorizations, :blob_id
    add_foreign_key :panda_core_file_categorizations, :active_storage_blobs, column: :blob_id
  end
end
