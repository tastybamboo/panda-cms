# frozen_string_literal: true

class AddPinnedPageIdsToPandaCMSMenus < ActiveRecord::Migration[8.1]
  def change
    add_column :panda_cms_menus, :pinned_page_ids, :jsonb, default: [], null: false
  end
end
