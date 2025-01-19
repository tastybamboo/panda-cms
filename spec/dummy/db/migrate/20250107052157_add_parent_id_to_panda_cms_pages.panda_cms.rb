# This migration comes from panda_cms (originally 20240304134343)
class AddParentIdToPandaCMSPages < ActiveRecord::Migration[7.1]
  def change
    add_reference :panda_cms_pages, :parent, type: :uuid, foreign_key: {to_table: :panda_cms_pages}
  end
end
