# This migration comes from panda_cms (originally 20240205223709)
class CreatePandaCMSPages < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_pages, id: :uuid do |t|
      t.string :title
      t.string :path
      t.timestamps
    end
  end
end
