# frozen_string_literal: true

class CreatePandaCMSProContentSyncLogs < ActiveRecord::Migration[8.0]
  def change
    # Create enum for sync type
    create_enum :panda_cms_pro_sync_type, ["push", "pull"]

    # Create enum for sync status
    create_enum :panda_cms_pro_sync_status,
                ["pending", "in_progress", "completed", "failed", "rolled_back"]

    create_table :panda_cms_pro_content_sync_logs, id: :uuid do |t|
      t.enum :sync_type, enum_type: "panda_cms_pro_sync_type", null: false
      t.enum :status, enum_type: "panda_cms_pro_sync_status",
             default: "pending", null: false
      t.uuid :user_id, null: false
      t.jsonb :items_synced, default: [], null: false
      t.jsonb :summary, default: {}
      t.text :error_log
      t.datetime :started_at
      t.datetime :completed_at
      t.string :source_environment
      t.string :destination_environment

      t.timestamps

      t.index :user_id
      t.index :status
      t.index :sync_type
      t.index :created_at
    end

    add_foreign_key :panda_cms_pro_content_sync_logs, :panda_core_users,
                    column: :user_id
  end
end
