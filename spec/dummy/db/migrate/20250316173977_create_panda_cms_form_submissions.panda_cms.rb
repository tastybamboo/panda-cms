# This migration comes from panda_cms (originally 20240805013612)
class CreatePandaCMSFormSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_cms_form_submissions, id: :uuid do |t|
      t.references :form, type: :uuid, null: false, foreign_key: {to_table: :panda_cms_forms}
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end
  end
end
