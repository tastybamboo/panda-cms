# frozen_string_literal: true

class AddPromoteActiveItemToPandaCMSMenus < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_cms_menus, :promote_active_item, :boolean, default: false, null: false
  end
end
