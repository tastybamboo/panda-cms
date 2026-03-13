# frozen_string_literal: true

# This migration comes from panda_core (originally 20260303000001)
class AddMetadataToPandaCoreUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :panda_core_users, :metadata, :jsonb, default: {}, null: false

    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      add_index :panda_core_users, :metadata, using: :gin, name: "index_panda_core_users_on_metadata"
    end
  end
end
