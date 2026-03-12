# frozen_string_literal: true

# This migration comes from panda_core (originally 20260217000001)
class CreatePandaCoreFeatureFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_core_feature_flags, id: :uuid do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false
      t.string :description
      t.timestamps
    end

    add_index :panda_core_feature_flags, :key, unique: true
  end
end
