# frozen_string_literal: true

class AddCurrentThemeToPandaCMSUsers < ActiveRecord::Migration[8.0]
  def change
    # This migration is obsolete - users are now in panda_core_users table
    # and current_theme was added to the core users table
  end
end
