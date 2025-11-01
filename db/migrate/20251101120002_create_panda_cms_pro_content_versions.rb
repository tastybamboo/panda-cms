# frozen_string_literal: true

class CreatePandaCmsProContentVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :panda_cms_pro_content_versions, id: :uuid do |t|
      t.string :versionable_type, null: false
      t.uuid :versionable_id, null: false
      t.integer :version_number, null: false, default: 1
      t.jsonb :content, null: false
      t.text :change_summary
      t.uuid :user_id
      t.string :source, default: "manual" # manual, ai_generated, suggestion_approved

      t.timestamps

      t.index [:versionable_type, :versionable_id],
              name: "index_pro_content_versions_on_versionable"
      t.index :user_id
      t.index :version_number
      t.index :created_at
    end

    add_foreign_key :panda_cms_pro_content_versions, :panda_core_users,
                    column: :user_id
  end
end
