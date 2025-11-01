# frozen_string_literal: true

class CreatePandaCMSProContentComments < ActiveRecord::Migration[8.0]
  def change
    create_table :panda_cms_pro_content_comments, id: :uuid do |t|
      t.string :commentable_type, null: false
      t.uuid :commentable_id, null: false
      t.uuid :user_id, null: false
      t.string :section_identifier
      t.text :content, null: false
      t.uuid :parent_id # For threaded comments
      t.boolean :resolved, default: false, null: false
      t.uuid :resolved_by_id
      t.datetime :resolved_at

      t.timestamps

      t.index [:commentable_type, :commentable_id],
              name: "index_pro_content_comments_on_commentable"
      t.index :user_id
      t.index :parent_id
      t.index :resolved
    end

    add_foreign_key :panda_cms_pro_content_comments, :panda_core_users,
                    column: :user_id
    add_foreign_key :panda_cms_pro_content_comments, :panda_core_users,
                    column: :resolved_by_id
    add_foreign_key :panda_cms_pro_content_comments, :panda_cms_pro_content_comments,
                    column: :parent_id
  end
end
