# frozen_string_literal: true

class AddPandaCMSMenuTable < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_menus, id: :uuid do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :panda_cms_menus, :name, unique: true
  end
end
