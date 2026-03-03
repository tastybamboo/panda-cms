# frozen_string_literal: true

class CreatePandaCMSSocialSharingNetworks < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_cms_social_sharing_networks, id: :uuid do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :panda_cms_social_sharing_networks, :key, unique: true
    add_index :panda_cms_social_sharing_networks, :position
  end
end
