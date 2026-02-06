# frozen_string_literal: true

# This migration comes from panda_core (originally 20260203000002)
class CreatePandaCoreUserActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_core_user_activities, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :action, null: false
      t.string :resource_type
      t.uuid :resource_id
      t.jsonb :metadata, default: {}
      t.string :ip_address
      t.string :user_agent

      t.timestamps

      t.index :user_id
      t.index [:resource_type, :resource_id]
      t.index :action
      t.index :created_at
    end

    add_foreign_key :panda_core_user_activities, :panda_core_users, column: :user_id
  end
end
