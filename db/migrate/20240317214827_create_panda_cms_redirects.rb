# frozen_string_literal: true

class CreatePandaCMSRedirects < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_redirects, id: :uuid do |t|
      t.string :origin_path, null: true
      t.string :destination_path, null: true
      t.references :origin_panda_cms_page, null: true, foreign_key: {to_table: :panda_cms_pages}, type: :uuid
      t.references :destination_panda_cms_page, null: true, foreign_key: {to_table: :panda_cms_pages}, type: :uuid
      t.integer :status_code, default: 301, null: false
      t.integer :visits, default: 0, null: false
      t.datetime :last_visited_at, null: true
      t.timestamps
    end
  end
end
