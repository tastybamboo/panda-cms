# frozen_string_literal: true

class CreatePandaCMSPages < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_pages, id: :uuid do |t|
      t.string :title
      t.string :path
      t.timestamps
    end
  end
end
