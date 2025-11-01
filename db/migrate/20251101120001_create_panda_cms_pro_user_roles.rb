# frozen_string_literal: true

class CreatePandaCMSProUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :panda_cms_pro_user_roles, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :panda_cms_pro_role_id, null: false
      t.datetime :expires_at
      t.string :access_token
      t.datetime :access_token_expires_at
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index :user_id
      t.index :panda_cms_pro_role_id
      t.index :access_token, unique: true
      t.index [:user_id, :panda_cms_pro_role_id], unique: true,
              name: "index_unique_user_role_pro"
    end

    add_foreign_key :panda_cms_pro_user_roles, :panda_core_users, column: :user_id
    add_foreign_key :panda_cms_pro_user_roles, :panda_cms_pro_roles
  end
end
