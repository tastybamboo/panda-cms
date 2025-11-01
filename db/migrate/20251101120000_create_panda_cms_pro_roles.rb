# frozen_string_literal: true

class CreatePandaCmsProRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :panda_cms_pro_roles, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      t.jsonb :permissions, default: {}, null: false
      t.jsonb :custom_metadata, default: {}
      t.boolean :system_role, default: false, null: false

      t.timestamps

      t.index :name, unique: true
    end
  end
end
