# frozen_string_literal: true

class DefaultPandaCMSUsersAdminToFalse < ActiveRecord::Migration[7.1]
  def change
    change_column :panda_cms_users, :admin, :boolean, default: false
  end
end
