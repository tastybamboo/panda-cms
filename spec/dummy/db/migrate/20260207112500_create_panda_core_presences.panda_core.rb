# frozen_string_literal: true

# This migration comes from panda_core (originally 20260207100000)
class CreatePandaCorePresences < ActiveRecord::Migration[8.1]
  def change
    create_table :panda_core_presences, id: :uuid do |t|
      t.string :presenceable_type, null: false
      t.uuid :presenceable_id, null: false
      t.uuid :user_id, null: false
      t.datetime :last_seen_at, null: false
      t.timestamps
    end

    add_index :panda_core_presences, [:presenceable_type, :presenceable_id, :user_id],
      unique: true, name: "index_unique_presence"
    add_index :panda_core_presences, [:presenceable_type, :presenceable_id],
      name: "index_presences_on_presenceable"
    add_index :panda_core_presences, :last_seen_at
    add_foreign_key :panda_core_presences, :panda_core_users, column: :user_id
  end
end
