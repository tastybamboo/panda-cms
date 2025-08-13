class MigrateUsersToPandaCore < ActiveRecord::Migration[8.0]
  def up
    # First ensure panda_core_users table exists (from Core engine)
    # It should already exist from the Core migration

    # Migrate data from panda_cms_users to panda_core_users if needed
    if table_exists?(:panda_cms_users) && table_exists?(:panda_core_users)
      # Check if there's any data to migrate
      cms_user_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM panda_cms_users")
      return if cms_user_count == 0
      # Copy all user data
      execute <<-SQL
        INSERT INTO panda_core_users (
          id, name, email, image_url, is_admin, created_at, updated_at
        )
        SELECT 
          id,
          COALESCE(name, CONCAT(firstname, ' ', lastname), 'Unknown User'),
          email,
          image_url,
          COALESCE(admin, false),
          created_at,
          updated_at
        FROM panda_cms_users
        WHERE NOT EXISTS (
          SELECT 1 FROM panda_core_users WHERE panda_core_users.id = panda_cms_users.id
        )
      SQL

      # Update foreign key references in other tables

      # Posts author_id
      if column_exists?(:panda_cms_posts, :author_id)
        remove_foreign_key :panda_cms_posts, column: :author_id if foreign_key_exists?(:panda_cms_posts, :panda_cms_users, column: :author_id)
        add_foreign_key :panda_cms_posts, :panda_core_users, column: :author_id, primary_key: :id
      end

      # Posts user_id (legacy column)
      if column_exists?(:panda_cms_posts, :user_id)
        remove_foreign_key :panda_cms_posts, column: :user_id if foreign_key_exists?(:panda_cms_posts, :panda_cms_users, column: :user_id)
        add_foreign_key :panda_cms_posts, :panda_core_users, column: :user_id, primary_key: :id
      end

      # Visits user_id
      if column_exists?(:panda_cms_visits, :user_id)
        remove_foreign_key :panda_cms_visits, column: :user_id if foreign_key_exists?(:panda_cms_visits, :panda_cms_users, column: :user_id)
        add_foreign_key :panda_cms_visits, :panda_core_users, column: :user_id, primary_key: :id
      end

      # Drop the old table
      drop_table :panda_cms_users
    end
  end

  def down
    # Recreate panda_cms_users table
    create_table :panda_cms_users, id: :uuid do |t|
      t.string :name
      t.string :firstname
      t.string :lastname
      t.string :email, null: false
      t.string :image_url
      t.boolean :admin, default: false
      t.string :current_theme, default: "default"
      t.timestamps
    end

    add_index :panda_cms_users, :email, unique: true

    # Migrate data back
    if table_exists?(:panda_core_users) && table_exists?(:panda_cms_users)
      execute <<-SQL
        INSERT INTO panda_cms_users (
          id, firstname, lastname, name, email, image_url, admin, current_theme, created_at, updated_at
        )
        SELECT 
          id,
          split_part(name, ' ', 1),
          CASE 
            WHEN position(' ' IN name) > 0 
            THEN substring(name FROM position(' ' IN name) + 1)
            ELSE ''
          END,
          name,
          email,
          image_url,
          is_admin,
          'default',
          created_at,
          updated_at
        FROM panda_core_users
      SQL

      # Restore foreign keys to panda_cms_users
      if column_exists?(:panda_cms_posts, :author_id)
        remove_foreign_key :panda_cms_posts, column: :author_id if foreign_key_exists?(:panda_cms_posts, column: :author_id)
        add_foreign_key :panda_cms_posts, :panda_cms_users, column: :author_id, primary_key: :id
      end

      if column_exists?(:panda_cms_posts, :user_id)
        remove_foreign_key :panda_cms_posts, column: :user_id if foreign_key_exists?(:panda_cms_posts, column: :user_id)
        add_foreign_key :panda_cms_posts, :panda_cms_users, column: :user_id, primary_key: :id
      end

      if column_exists?(:panda_cms_visits, :user_id)
        remove_foreign_key :panda_cms_visits, column: :user_id if foreign_key_exists?(:panda_cms_visits, column: :user_id)
        add_foreign_key :panda_cms_visits, :panda_cms_users, column: :user_id, primary_key: :id
      end
    end
  end
end
