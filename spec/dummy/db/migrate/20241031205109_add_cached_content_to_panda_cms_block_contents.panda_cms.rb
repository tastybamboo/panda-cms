# This migration comes from panda_cms (originally 20241031205109)
class AddCachedContentToPandaCMSBlockContents < ActiveRecord::Migration[7.2]
  def change
    add_column :panda_cms_block_contents, :cached_content, :jsonb
  end
end
