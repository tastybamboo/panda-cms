# This migration comes from panda_cms (originally 20240316212822)
class AddKindToPandaCMSMenus < ActiveRecord::Migration[7.1]
  def change
    # create_enum :panda_cms_menu_kind, ["static", "auto"]
    # add_column :panda_cms_menus, :kind, :enum, enum_type: :panda_cms_menu_kind, default: "static", null: false
  end
end
