# frozen_string_literal: true

# This migration comes from panda_core (originally 20260310000002)
class CreatePandaCoreImportSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_core_import_sessions, id: :uuid do |t|
      t.string :importable_type, null: false
      t.string :tenant_type
      t.bigint :tenant_id
      t.uuid :user_id, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :column_mapping, default: {}, null: false
      t.integer :total_rows, default: 0, null: false
      t.integer :processed_rows, default: 0, null: false
      t.integer :imported_count, default: 0, null: false
      t.integer :skipped_count, default: 0, null: false
      t.integer :error_count, default: 0, null: false
      t.jsonb :errors_log, default: [], null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps

      t.index [:tenant_type, :tenant_id]
      t.index :status
      t.index :user_id
    end

    add_foreign_key :panda_core_import_sessions, :panda_core_users, column: :user_id
  end
end
