# This migration comes from panda_cms (originally 20240806112735)
class FixPandaCMSVisitsColumnNames < ActiveRecord::Migration[7.1]
  def change
    change_table :panda_cms_visits do |t|
      t.rename :panda_cms_page_id, :page_id
      t.rename :panda_cms_redirect_id, :redirect_id
      t.rename :panda_cms_user_id, :user_id
      t.string :referrer, null: true
      t.datetime :visited_at
      t.string :url, null: true
      t.jsonb :params, null: true
    end
  end
end
