# This migration comes from panda_cms (originally 20240806204412)
class AddCompletionPathToPandaCMSForms < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_cms_forms, :completion_path, :string
  end
end
