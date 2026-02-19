# frozen_string_literal: true

class AddCompositeNestedSetIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :panda_cms_menu_items, [:panda_cms_menu_id, :lft, :rgt],
      name: "index_panda_cms_menu_items_on_menu_lft_rgt"

    remove_index :panda_cms_menu_items, :lft, name: "index_panda_cms_menu_items_on_lft"
    remove_index :panda_cms_menu_items, :rgt, name: "index_panda_cms_menu_items_on_rgt"
  end
end
