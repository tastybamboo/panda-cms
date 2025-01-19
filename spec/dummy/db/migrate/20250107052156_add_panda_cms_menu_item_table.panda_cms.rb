# This migration comes from panda_cms (originally 20240303234724)
class AddPandaCMSMenuItemTable < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_menu_items, id: :uuid do |t|
      t.string :text, null: false
      t.references :panda_cms_menu, null: false, foreign_key: true, type: :uuid
      t.references :panda_cms_page, null: true, foreign_key: true, type: :uuid
      t.string :external_url, null: true
      t.integer :sort_order, default: 1
      t.timestamps
    end
  end
end
