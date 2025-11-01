# frozen_string_literal: true

class CreatePandaCmsProContentSources < ActiveRecord::Migration[8.0]
  def change
    # Create enum for trust level
    create_enum :panda_cms_pro_source_trust_level,
                ["always_prefer", "trusted", "neutral", "untrusted", "never_use"]

    create_table :panda_cms_pro_content_sources, id: :uuid do |t|
      t.string :domain, null: false
      t.enum :trust_level, enum_type: "panda_cms_pro_source_trust_level",
             default: "neutral", null: false
      t.string :default_callout_type
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index :domain, unique: true
      t.index :trust_level
    end
  end
end
