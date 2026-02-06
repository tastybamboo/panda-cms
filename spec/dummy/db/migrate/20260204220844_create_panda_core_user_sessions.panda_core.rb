# frozen_string_literal: true

# This migration comes from panda_core (originally 20260203000003)
class CreatePandaCoreUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_core_user_sessions, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :session_id, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_active_at
      t.boolean :active, default: true, null: false
      t.datetime :revoked_at
      t.uuid :revoked_by_id

      t.timestamps

      t.index :session_id, unique: true
      t.index :user_id
      t.index :active
    end

    add_foreign_key :panda_core_user_sessions, :panda_core_users, column: :user_id
    add_foreign_key :panda_core_user_sessions, :panda_core_users, column: :revoked_by_id, on_delete: :nullify
  end
end
