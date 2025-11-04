class AddPageTypeToPandaCMSPages < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_pages, :page_type, :string, default: "standard", null: false
    add_index :panda_cms_pages, :page_type
  end
end
