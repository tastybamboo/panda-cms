# frozen_string_literal: true

class AddOrderingToPandaCMSMenus < ActiveRecord::Migration[7.1]
  def change
    create_enum :panda_cms_menu_ordering, %w[default alphabetical]
    add_column :panda_cms_menus, :ordering, :enum, enum_type: :panda_cms_menu_ordering, default: "default", null: false
  end
end
