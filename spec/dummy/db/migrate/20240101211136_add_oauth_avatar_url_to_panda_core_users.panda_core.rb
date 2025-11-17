# frozen_string_literal: true

# This migration comes from panda_core (originally 20250811120000)
class AddOauthAvatarUrlToPandaCoreUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_core_users, :oauth_avatar_url, :string
  end
end
