# frozen_string_literal: true

# This migration comes from panda_core (originally 20260203000001)
class AddUserManagementFieldsToPandaCoreUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :panda_core_users, bulk: true do |t|
      t.boolean :enabled, default: true, null: false
      t.datetime :last_login_at
      t.string :last_login_ip
      t.integer :login_count, default: 0, null: false
      t.uuid :invited_by_id
      t.string :invitation_token
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
    end

    add_index :panda_core_users, :invitation_token, unique: true
    add_index :panda_core_users, :invited_by_id
    add_index :panda_core_users, :enabled
    add_foreign_key :panda_core_users, :panda_core_users, column: :invited_by_id
  end
end
