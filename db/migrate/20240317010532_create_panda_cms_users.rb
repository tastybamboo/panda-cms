# frozen_string_literal: true

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
