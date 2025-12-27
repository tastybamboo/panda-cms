# frozen_string_literal: true

class AddFileSupportToPandaCMSFormSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_form_submissions, :files_metadata, :jsonb, default: {}
  end
end
