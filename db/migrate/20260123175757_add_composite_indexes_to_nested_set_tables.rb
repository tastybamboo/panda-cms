class AddCompositeIndexesToNestedSetTables < ActiveRecord::Migration[8.0]
  def change
    # Composite index for nested set queries on menu items
    # Supports: WHERE panda_cms_menu_id = ? AND lft BETWEEN ? AND ?
    add_index :panda_cms_menu_items, [:panda_cms_menu_id, :lft, :rgt],
      name: "index_menu_items_on_menu_id_and_nested_set",
      if_not_exists: true

    # Composite index for nested set queries on pages
    # Supports: WHERE lft BETWEEN ? AND ? ORDER BY lft
    add_index :panda_cms_pages, [:lft, :rgt],
      name: "index_pages_on_nested_set",
      if_not_exists: true

    # Composite index for pages parent lookups
    # Supports: WHERE parent_id = ? ORDER BY lft
    add_index :panda_cms_pages, [:parent_id, :lft],
      name: "index_pages_on_parent_and_lft",
      if_not_exists: true
  end
end
