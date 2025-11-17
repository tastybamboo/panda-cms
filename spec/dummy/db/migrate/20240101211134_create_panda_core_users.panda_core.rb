# frozen_string_literal: true

# This migration comes from panda_core (originally 20250809000001)
class CreatePandaCoreUsers < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:panda_core_users)
      create_table :panda_core_users, id: :uuid do |t|
        t.string :name
        t.string :email, null: false
        t.string :image_url
        t.boolean :is_admin, default: false, null: false
        t.timestamps
      end

      add_index :panda_core_users, :email, unique: true
    end
  end
end
