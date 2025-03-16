# This migration comes from panda_cms (originally 20240820081917)
class ChangeFormSubmissionsToSubmissionCount < ActiveRecord::Migration[7.2]
  def change
    rename_column :panda_cms_forms, :submissions, :submission_count
  end
end
