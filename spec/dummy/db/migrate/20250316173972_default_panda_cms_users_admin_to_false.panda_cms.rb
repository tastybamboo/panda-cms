# This migration comes from panda_cms (originally 20240408084718)
class DefaultPandaCMSUsersAdminToFalse < ActiveRecord::Migration[7.1]
  def change
    change_column :panda_cms_users, :admin, :boolean, default: false
  end
end
