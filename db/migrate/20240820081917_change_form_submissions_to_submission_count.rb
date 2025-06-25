# frozen_string_literal: true

class ChangeFormSubmissionsToSubmissionCount < ActiveRecord::Migration[7.2]
  def change
    rename_column :panda_cms_forms, :submissions, :submission_count
  end
end
