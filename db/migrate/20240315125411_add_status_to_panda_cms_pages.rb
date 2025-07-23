# frozen_string_literal: true

class AddStatusToPandaCMSPages < ActiveRecord::Migration[7.1]
  def change
    return if column_exists?(:panda_cms_pages, :status)

    create_enum :panda_cms_page_status, %w[active draft hidden archived]
    add_column :panda_cms_pages, :status, :panda_cms_page_status, default: "active", null: false
    add_index :panda_cms_pages, :status
  end
end
