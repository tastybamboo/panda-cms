# frozen_string_literal: true

# This migration comes from panda_core (originally 20260213000001)
class FixActiveStorageAttachmentsRecordIdType < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:active_storage_attachments)

    column = columns(:active_storage_attachments).find { |c| c.name == "record_id" }
    return if column.nil? || column.sql_type == "character varying"

    # Remove orphaned attachments where UUID was silently cast to 0
    execute <<~SQL
      DELETE FROM active_storage_attachments WHERE record_id = 0
    SQL

    # Drop the unique index before changing the column type
    remove_index :active_storage_attachments,
      name: "index_active_storage_attachments_uniqueness",
      if_exists: true

    change_column :active_storage_attachments, :record_id, :string, null: false

    add_index :active_storage_attachments,
      [:record_type, :record_id, :name, :blob_id],
      unique: true,
      name: "index_active_storage_attachments_uniqueness"
  end

  def down
    return unless table_exists?(:active_storage_attachments)

    remove_index :active_storage_attachments,
      name: "index_active_storage_attachments_uniqueness",
      if_exists: true

    change_column :active_storage_attachments, :record_id, :bigint,
      null: false,
      using: "record_id::bigint"

    add_index :active_storage_attachments,
      [:record_type, :record_id, :name, :blob_id],
      unique: true,
      name: "index_active_storage_attachments_uniqueness"
  end
end
