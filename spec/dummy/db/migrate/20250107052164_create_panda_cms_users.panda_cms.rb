# This migration comes from panda_cms (originally 20240317010532)
class CreatePandaCMSUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_users, id: :uuid do |t|
      t.string :firstname
      t.string :lastname
      t.string :email
      t.string :image_url
      t.boolean :admin
      t.timestamps
    end
  end
end
