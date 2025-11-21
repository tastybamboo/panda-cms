# frozen_string_literal: true

class AddDepthToPandaCMSMenus < ActiveRecord::Migration[7.2]
  def change
    add_column :panda_cms_menus, :depth, :integer, null: true, default: nil
  end
end
