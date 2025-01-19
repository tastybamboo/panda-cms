# This migration comes from panda_cms (originally 20240303002805)
class CreatePandaCMSTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_templates, id: :uuid do |t|
      t.string :name
      t.string :file_path
      t.timestamps
    end

    add_reference :panda_cms_pages, :panda_cms_template, type: :uuid, foreign_key: {to_table: :panda_cms_templates}, null: false
  end
end
