class ConsolidateUserNameColumns < ActiveRecord::Migration[8.0]
  def up
    # Add name column if it doesn't exist
    add_column :panda_core_users, :name, :string unless column_exists?(:panda_core_users, :name)

    # Migrate data: combine firstname and lastname into name (only if old columns exist)
    if column_exists?(:panda_core_users, :firstname) || column_exists?(:panda_core_users, :lastname)
      execute <<-SQL
        UPDATE panda_core_users
        SET name = TRIM(COALESCE(firstname, '') || ' ' || COALESCE(lastname, ''))
        WHERE (firstname IS NOT NULL OR lastname IS NOT NULL)
        AND (name IS NULL OR name = '')
      SQL
    end

    # Remove old columns
    remove_column :panda_core_users, :firstname if column_exists?(:panda_core_users, :firstname)
    remove_column :panda_core_users, :lastname if column_exists?(:panda_core_users, :lastname)
  end

  def down
    # Add back firstname and lastname
    add_column :panda_core_users, :firstname, :string unless column_exists?(:panda_core_users, :firstname)
    add_column :panda_core_users, :lastname, :string unless column_exists?(:panda_core_users, :lastname)

    # Split name back into firstname and lastname (best effort, only if name column exists)
    if column_exists?(:panda_core_users, :name)
      execute <<-SQL
        UPDATE panda_core_users
        SET firstname = SPLIT_PART(name, ' ', 1),
            lastname = SUBSTRING(name FROM POSITION(' ' IN name) + 1)
        WHERE name IS NOT NULL AND name != ''
      SQL
    end

    # Remove name column
    remove_column :panda_core_users, :name if column_exists?(:panda_core_users, :name)
  end
end
