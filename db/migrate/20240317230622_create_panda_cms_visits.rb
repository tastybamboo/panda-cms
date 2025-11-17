# frozen_string_literal: true

class CreatePandaCMSVisits < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_visits, id: :uuid do |t|
      t.string :ip_address, null: true
      t.string :user_agent, null: true

      t.references :panda_cms_page, null: true, foreign_key: true, type: :uuid
      t.references :panda_cms_redirect, null: true, foreign_key: true, type: :uuid
      t.references :panda_core_user, null: true, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
