# frozen_string_literal: true

class AddProContributorTrackingToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_pages, :contributor_count, :integer, default: 0
    add_column :panda_cms_pages, :last_contributed_at, :datetime
    add_column :panda_cms_pages, :workflow_status, :string, default: "draft"

    add_index :panda_cms_pages, :workflow_status
    add_index :panda_cms_pages, :last_contributed_at
  end
end
