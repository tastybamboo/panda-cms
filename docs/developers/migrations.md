# Panda Gem Migrations Guide

This guide explains how database migrations work across the Panda ecosystem (panda-core, panda-cms, and panda-cms-pro).

## Migration Strategy

**All Panda gems follow the Rails-recommended "copy to host app" approach** as documented in the [Rails Engines Guide](https://guides.rubyonrails.org/engines.html).

### How It Works

1. **Migrations stay in the engine** - Each gem keeps its migrations in `db/migrate/`
2. **Copy to host app** - When you install or update a gem, you copy its migrations to your app
3. **New timestamps** - Copied migrations get new timestamps reflecting when they were copied
4. **Rails manages them** - Once copied, Rails treats them as regular migrations

### Why This Approach?

This is the official Rails recommendation for engines because:

- ✅ Host app has full control over migrations
- ✅ Migrations can be modified if needed for specific apps
- ✅ Clear chronological order of when features were added to the app
- ✅ Prevents migration conflicts between engines
- ✅ Works reliably across all environments (development, CI, production)

## Gem-Specific Details

### Panda Core

**Migration location:** `panda-core/db/migrate/`

**Installation:**
```bash
rails panda_core:install:migrations
rails db:migrate
```

**Tables created:**
- `panda_core_users` - User authentication
- `panda_core_sessions` - Session management (if applicable)

### Panda CMS

**Migration location:** `panda-cms/db/migrate/`

**Installation:**
```bash
rails panda_cms:install:migrations
rails db:migrate
```

**Tables created:**
- `panda_cms_pages` - Content pages
- `panda_cms_posts` - Blog posts
- `panda_cms_templates` - Page templates
- `panda_cms_blocks` - Content blocks
- `panda_cms_block_contents` - Block content data
- `panda_cms_menus` - Navigation menus
- `panda_cms_menu_items` - Menu items
- `panda_cms_forms` - Contact forms
- `panda_cms_form_submissions` - Form submissions
- Plus related tables

### Panda CMS Pro

**Migration location:** `panda-cms-pro/db/migrate/`

**Installation:**
```bash
rails panda_cms_pro:install:migrations
rails db:migrate
```

**Tables created:**
- `panda_cms_pro_roles` - User roles and permissions
- `panda_cms_pro_user_roles` - User-role associations
- `panda_cms_pro_content_versions` - Content versioning
- `panda_cms_pro_content_changes` - Change tracking
- `panda_cms_pro_content_suggestions` - Content suggestions
- `panda_cms_pro_content_comments` - Comments
- `panda_cms_pro_content_sources` - External sources
- `panda_cms_pro_content_sync_logs` - Sync logs
- `panda_cms_collections` - Custom collections
- `panda_cms_collection_fields` - Collection field definitions
- `panda_cms_collection_items` - Collection data
- `panda_cms_pro_provider_configurations` - AI provider configs

## Common Tasks

### Initial Installation

When first setting up a Rails app with Panda gems:

```bash
# Add gems to Gemfile
gem "panda-core", "~> 0.6.0"
gem "panda-cms", "~> 0.10.0"
gem "panda-cms-pro", "~> 0.1.0"  # optional

# Install gems
bundle install

# Copy all engine migrations at once
rails railties:install:migrations

# Run migrations
rails db:migrate
```

The `railties:install:migrations` command copies migrations from ALL engines at once, which is more efficient than running each gem's install task separately.

### Updating a Gem

When you update a Panda gem to a new version:

```bash
# Update gem version in Gemfile
gem "panda-cms", "~> 0.11.0"

# Update bundle
bundle update panda-cms

# Copy any new migrations
rails panda_cms:install:migrations

# Run new migrations
rails db:migrate
```

### Copying Migrations from All Gems

To copy migrations from all Panda gems at once:

```bash
rails railties:install:migrations
rails db:migrate
```

This is useful when:
- Setting up a new environment
- Multiple gems have been updated
- You want to ensure all migrations are copied

### Checking Migration Status

To see which migrations have been run:

```bash
rails db:migrate:status
```

Migrations from engine gems will show with their copied timestamps and filenames ending in `.panda_cms.rb`, `.panda_core.rb`, or `.panda_cms_pro.rb`.

## How Copying Works

When you run `rails ENGINE:install:migrations`, Rails:

1. **Scans** the engine's `db/migrate/` directory
2. **Compares** with migrations already in your app's `db/migrate/`
3. **Copies** only new migrations (not already copied)
4. **Renames** them with new timestamps (current time)
5. **Adds suffix** like `.panda_cms.rb` to track the source

Example:
```
Engine:    20251110114258_add_spam_tracking_to_form_submissions.rb
Copied to: 20251205143022_add_spam_tracking_to_form_submissions.panda_cms.rb
           └─ new timestamp                                      └─ source suffix
```

## Development Workflow

### For Engine Development (panda-core, panda-cms, panda-cms-pro)

When developing the gems themselves:

1. **Create migrations** in the engine's `db/migrate/`
2. **Copy to test app** (spec/dummy):
   ```bash
   # For panda-cms
   rails panda:cms:test:prepare

   # This copies all migrations and recreates test database
   ```
3. **Run migrations** in test environment:
   ```bash
   cd spec/dummy
   RAILS_ENV=test rails db:migrate
   ```

### For Host App Development (neurobetter, etc.)

When using the gems in a Rails app:

1. **Update Gemfile** with new gem version
2. **Run bundle update**
3. **Copy new migrations**: `rails railties:install:migrations`
4. **Run migrations**: `rails db:migrate`
5. **Commit** the new migration files to version control

## File Naming Conventions

Copied migrations include a suffix to indicate their source:

- `.panda_core.rb` - From panda-core gem
- `.panda_cms.rb` - From panda-cms gem
- `.panda_cms_pro.rb` - From panda-cms-pro gem

These suffixes help identify which gem a migration came from, making it easier to track changes and troubleshoot issues.

## Troubleshooting

### Problem: "relation already exists" errors

**Cause:** Migration files were copied multiple times or copied manually without proper tracking.

**Solution:**
1. Check which migrations are in your `db/migrate/` directory
2. Remove duplicate migration files
3. Verify `schema_migrations` table reflects actual database state
4. If needed, manually insert/remove migration versions in the database

### Problem: Migrations not being copied

**Cause:** Rails thinks the migration has already been copied (checks by migration name, not timestamp).

**Solution:**
- Migrations with the same name won't be copied again
- This is intentional - prevents duplicates
- If you need to re-copy, temporarily rename the migration in the engine

### Problem: CI failures due to "pending migrations"

**Cause:** Test database schema doesn't match migration files.

**Solution:**
```bash
# Reset test database completely
RAILS_ENV=test rails db:drop db:create db:migrate

# Or use schema load for faster setup
RAILS_ENV=test rails db:schema:load
```

### Problem: Mixed up migration order

**Cause:** Copied migrations get new timestamps, which may be different from development order.

**Solution:**
- This is expected and normal
- Each environment may have slightly different timestamp order
- The important thing is that migrations run successfully
- `schema.rb` should be identical across environments

## Best Practices

1. **Always copy migrations after updating gems**
   - Don't assume migrations are automatically available
   - Use `railties:install:migrations` regularly

2. **Commit copied migrations to version control**
   - Your app's migration history is important
   - Other developers need the same migrations

3. **Don't manually edit copied migrations**
   - If a migration needs changes, update it in the engine
   - Then re-copy and run it

4. **Use schema.rb as the source of truth**
   - Different environments may have different migration timestamps
   - Schema.rb should always be identical

5. **Keep Gemfile.lock in version control**
   - Ensures everyone uses the same gem versions
   - Makes migration copying consistent

## References

- [Rails Engines Guide - Migrations](https://guides.rubyonrails.org/engines.html#migrations)
- [Rails Migration Guide](https://guides.rubyonrails.org/active_record_migrations.html)
- [Panda CMS Release Notes](../release-notes/)
