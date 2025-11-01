# frozen_string_literal: true

class CreatePandaCMSProContentSuggestions < ActiveRecord::Migration[8.0]
  def change
    # Create enum for suggestion status
    create_enum :panda_cms_pro_suggestion_status,
                ["pending", "specialist_review", "admin_review", "approved", "rejected"]

    # Create enum for suggestion type
    create_enum :panda_cms_pro_suggestion_type,
                ["edit", "addition", "deletion", "comment", "citation"]

    create_table :panda_cms_pro_content_suggestions, id: :uuid do |t|
      t.string :suggestable_type, null: false
      t.uuid :suggestable_id, null: false
      t.uuid :user_id, null: false
      t.string :section_identifier
      t.enum :suggestion_type, enum_type: "panda_cms_pro_suggestion_type",
             null: false
      t.enum :status, enum_type: "panda_cms_pro_suggestion_status",
             default: "pending", null: false
      t.text :content, null: false
      t.text :rationale
      t.jsonb :metadata, default: {}
      t.uuid :reviewed_by_id
      t.datetime :reviewed_at
      t.text :admin_notes
      t.boolean :requires_specialist_review, default: false

      t.timestamps

      t.index [:suggestable_type, :suggestable_id],
              name: "index_pro_content_suggestions_on_suggestable"
      t.index :user_id
      t.index :reviewed_by_id
      t.index :status
      t.index :suggestion_type
      t.index :created_at
    end

    add_foreign_key :panda_cms_pro_content_suggestions, :panda_core_users,
                    column: :user_id
    add_foreign_key :panda_cms_pro_content_suggestions, :panda_core_users,
                    column: :reviewed_by_id
  end
end
