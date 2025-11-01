# frozen_string_literal: true

class CreatePandaCmsProContentChanges < ActiveRecord::Migration[8.0]
  def change
    # Create enum for change types
    create_enum :panda_cms_pro_content_change_type,
                ["addition", "deletion", "modification", "callout", "citation"]

    create_table :panda_cms_pro_content_changes, id: :uuid do |t|
      t.uuid :panda_cms_pro_content_version_id, null: false
      t.string :section_identifier
      t.enum :change_type, enum_type: "panda_cms_pro_content_change_type",
             null: false
      t.text :old_content
      t.text :new_content
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index :panda_cms_pro_content_version_id,
              name: "index_pro_content_changes_on_version"
      t.index :change_type
    end

    add_foreign_key :panda_cms_pro_content_changes,
                    :panda_cms_pro_content_versions
  end
end
