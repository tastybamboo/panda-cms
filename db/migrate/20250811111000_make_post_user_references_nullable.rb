# frozen_string_literal: true

class MakePostUserReferencesNullable < ActiveRecord::Migration[8.0]
  def change
    # Make user_id and author_id nullable for posts
    # This is needed because fixtures can't reference users from another gem
    # Tests that need users will set them programmatically
    change_column_null :panda_cms_posts, :user_id, true
    change_column_null :panda_cms_posts, :author_id, true
  end
end
