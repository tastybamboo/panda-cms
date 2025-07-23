# frozen_string_literal: true

class AddCompletionPathToPandaCMSForms < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_cms_forms, :completion_path, :string
  end
end
