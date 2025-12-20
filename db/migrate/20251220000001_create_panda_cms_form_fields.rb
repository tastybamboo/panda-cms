# frozen_string_literal: true

class CreatePandaCmsFormFields < ActiveRecord::Migration[8.0]
  def change
    create_table :panda_cms_form_fields, id: :uuid do |t|
      t.references :form, type: :uuid, null: false, foreign_key: {to_table: :panda_cms_forms}
      t.string :name, null: false
      t.string :label, null: false
      t.string :field_type, null: false
      t.text :placeholder
      t.text :hint
      t.text :options
      t.text :validations
      t.boolean :required, default: false
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :panda_cms_form_fields, [:form_id, :position]
    add_index :panda_cms_form_fields, [:form_id, :name], unique: true
  end
end
