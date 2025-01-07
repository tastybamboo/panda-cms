# This migration comes from panda_cms (originally 20240315125421)
class AddNestedSetsToPandaCMSPages < ActiveRecord::Migration[7.1]
  def self.up
    Panda::CMS::Page.where(parent_id: 0).update_all(parent_id: nil)
    add_column :panda_cms_pages, :lft, :integer
    add_column :panda_cms_pages, :rgt, :integer

    # This is necessary to update :lft and :rgt columns
    Panda::CMS::Page.reset_column_information
    Panda::CMS::Page.rebuild!
  end

  def self.down
    remove_column :panda_cms_pages, :lft
    remove_column :panda_cms_pages, :rgt
  end
end
