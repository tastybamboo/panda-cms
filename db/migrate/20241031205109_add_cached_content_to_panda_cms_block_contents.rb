# frozen_string_literal: true

class AddCachedContentToPandaCMSBlockContents < ActiveRecord::Migration[7.2]
  def change
    add_column :panda_cms_block_contents, :cached_content, :jsonb
  end
end
