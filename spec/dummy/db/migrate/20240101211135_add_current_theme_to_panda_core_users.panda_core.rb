# frozen_string_literal: true

# This migration comes from panda_core (originally 20250810120000)
class AddCurrentThemeToPandaCoreUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_core_users, :current_theme, :string unless column_exists?(:panda_core_users, :current_theme)
  end
end
