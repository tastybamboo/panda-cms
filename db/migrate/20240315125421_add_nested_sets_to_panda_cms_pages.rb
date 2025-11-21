# frozen_string_literal: true

class AddNestedSetsToPandaCMSPages < ActiveRecord::Migration[7.1]
  def self.up
    add_column :panda_cms_pages, :lft, :integer
    add_column :panda_cms_pages, :rgt, :integer
  end

  def self.down
    remove_column :panda_cms_pages, :lft
    remove_column :panda_cms_pages, :rgt
  end
end
