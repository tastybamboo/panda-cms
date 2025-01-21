# This migration comes from panda_cms (originally 20240320000000)
class FixVisitsPageIdColumn < ActiveRecord::Migration[7.1]
  def change
    rename_column :panda_cms_visits, :page_id, :panda_cms_page_id
  end
end
