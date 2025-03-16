# This migration comes from panda_cms (originally 20250120235542)
class RemovePaperTrail < ActiveRecord::Migration[7.1]
  def up
    version_tables = %w[
      panda_cms_versions
      panda_cms_version_associations
      panda_cms_template_versions
      panda_cms_page_versions
      panda_cms_block_content_versions
      panda_cms_post_versions
      action_text_rich_text_versions
    ]

    version_tables.each do |table|
      if table_exists?(table)
        drop_table table
      end
    end
  end

  def down
    create_table :panda_cms_versions do |t|
      t.string :item_type, null: false
      t.uuid :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.jsonb :object
      t.jsonb :object_changes
      t.datetime :created_at
    end
    add_index :panda_cms_versions, %i[item_type item_id]

    create_table :panda_cms_version_associations do |t|
      t.integer :version_id
      t.string :foreign_key_name, null: false
      t.integer :foreign_key_id
      t.string :foreign_type
    end
    add_index :panda_cms_version_associations, [:version_id]
    add_index :panda_cms_version_associations, [:foreign_key_name, :foreign_key_id, :foreign_type], name: "index_version_associations_on_foreign_key"

    # Model-specific version tables
    %w[template page block_content post action_text_rich_text].each do |model|
      create_table "panda_cms_#{model}_versions" do |t|
        t.string :item_type, null: false
        t.uuid :item_id, null: false
        t.string :event, null: false
        t.string :whodunnit
        t.jsonb :object
        t.jsonb :object_changes
        t.datetime :created_at
      end
      add_index "panda_cms_#{model}_versions", %i[item_type item_id]
    end
  end
end
