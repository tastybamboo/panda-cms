# frozen_string_literal: true

class AddDisplayOnSummaryToPandaCMSFormFields < ActiveRecord::Migration[7.2]
  def change
    add_column :panda_cms_form_fields, :display_on_summary, :boolean, default: false, null: false
  end
end
