# frozen_string_literal: true

class AddNestedSetsToPandaCMSPages < ActiveRecord::Migration[7.1]
  def self.up
    Panda::CMS::Page.where(parent_id: 0).update_all(parent_id: nil)
    add_column :panda_cms_pages, :lft, :integer
    add_column :panda_cms_pages, :rgt, :integer

    # This is necessary to update :lft and :rgt columns
    Panda::CMS::Page.reset_column_information

    # Only rebuild if there are existing pages
    # On fresh installs, there won't be any pages yet
    if Panda::CMS::Page.any?
      Panda::CMS::Page.rebuild!
    end
  end

  def self.down
    remove_column :panda_cms_pages, :lft
    remove_column :panda_cms_pages, :rgt
  end
end
