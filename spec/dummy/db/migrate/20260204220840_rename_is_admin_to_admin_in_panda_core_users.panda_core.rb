# frozen_string_literal: true

# This migration comes from panda_core (originally 20251203100000)
class RenameIsAdminToAdminInPandaCoreUsers < ActiveRecord::Migration[7.1]
  def up
    # If apps created an `is_admin` column during the brief rename, move it back
    return unless column_exists?(:panda_core_users, :is_admin)
    return if column_exists?(:panda_core_users, :admin)

    rename_column :panda_core_users, :is_admin, :admin
  end

  def down
    return unless column_exists?(:panda_core_users, :admin)
    return if column_exists?(:panda_core_users, :is_admin)

    rename_column :panda_core_users, :admin, :is_admin
  end
end
