#!/usr/bin/env ruby
#
# Extracted from db/migrate/20250809231125_migrate_users_to_panda_core

# First ensure panda_core_users table exists (from Core engine)
# It should already exist from the Core migration

## UP
# Migrate data from panda_cms_users to panda_core_users if needed
if table_exists?(:panda_cms_users) && table_exists?(:panda_core_users)
  # Check if there's any data to migrate
  cms_user_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM panda_cms_users")

  if cms_user_count > 0
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
  end
end

## DOWN
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
