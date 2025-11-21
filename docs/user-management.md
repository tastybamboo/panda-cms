---
title: User Management
layout: default
nav_order: 5
---

# User Management

Panda Core provides Rake tasks for managing users and their admin privileges. These tasks are useful for:
- Granting/revoking admin access
- Creating admin users for testing or deployment
- Auditing user accounts
- Managing user lifecycle

## Available Tasks

### List All Users

View all users in the system with their admin status:

```bash
rails panda:core:users:list
```

**Example Output:**
```
Users:
--------------------------------------------------------------------------------
admin@example.com                        [ADMIN]
user@example.com
james@jamesinman.co.uk                   [ADMIN]
--------------------------------------------------------------------------------
Total: 3 (2 admins)
```

### Grant Admin Privileges

Make an existing user an administrator:

```bash
rails panda:core:users:grant_admin EMAIL=user@example.com
```

**Example Output:**
```
✓ Granted admin privileges to 'user@example.com'
```

**Error Cases:**
- Email not provided: Shows usage instructions
- User not found: Lists all existing users
- User already admin: Confirms current status

### Revoke Admin Privileges

Remove admin privileges from a user:

```bash
rails panda:core:users:revoke_admin EMAIL=user@example.com
```

**Example Output:**
```
✓ Revoked admin privileges from 'user@example.com'
```

**Safety Features:**
- Cannot revoke the last admin user
- Prevents accidentally locking yourself out of the admin area

**Error Cases:**
```
Error: Cannot revoke admin privileges from the last admin user
Please create another admin first
```

### Create Admin User

Create a new user with admin privileges:

```bash
# Basic usage (uses default name "Admin User")
rails panda:core:users:create_admin EMAIL=admin@example.com

# With custom name
rails panda:core:users:create_admin EMAIL=admin@example.com NAME='John Doe'
```

**Example Output:**
```
✓ Created admin user 'admin@example.com'
  Name: John Doe
  Admin: true
```

**Use Cases:**
- **Initial Setup**: Create the first admin user during deployment
- **Testing**: Quickly create admin users in development/test environments
- **Recovery**: Create a new admin if locked out (requires direct database access)

**Error Cases:**
- Email not provided: Shows usage instructions
- User already exists: Suggests using `grant_admin` instead

### Delete User

Remove a user from the system:

```bash
rails panda:core:users:delete EMAIL=user@example.com
```

**Example Output:**
```
✓ Deleted user 'user@example.com'
```

**Safety Features:**
- Cannot delete the last admin user
- Prevents accidentally removing all administrative access

**Error Cases:**
```
Error: Cannot delete the last admin user
Please create another admin first
```

## Schema Compatibility

All tasks automatically detect and work with both schema versions:

- **Main Application Schema**: Uses `name` column
- **Test/CMS Schema**: Uses `firstname` and `lastname` columns

This ensures the tasks work correctly whether you're in development, test, or production environments.

## Common Workflows

### Initial Deployment Setup

When deploying to a new environment:

```bash
# Create the first admin user
rails panda:core:users:create_admin EMAIL=admin@example.com NAME='Admin User'

# Verify the user was created
rails panda:core:users:list
```

### Making an Existing User an Admin

When a new team member needs admin access:

```bash
# User logs in via OAuth (creates their account automatically)
# Then grant them admin privileges
rails panda:core:users:grant_admin EMAIL=newuser@company.com
```

### Auditing User Accounts

Regular security audit:

```bash
# List all users and their admin status
rails panda:core:users:list

# Review the output and revoke unnecessary admin access
rails panda:core:users:revoke_admin EMAIL=oldadmin@company.com
```

### Development/Testing Setup

Quick setup for local development:

```bash
# Create a test admin user
rails panda:core:users:create_admin EMAIL=dev@example.com

# Or use the developer OAuth strategy (no real OAuth credentials needed)
# See: Authentication Providers documentation
```

### User Cleanup

Removing inactive or test users:

```bash
# Delete test users
rails panda:core:users:delete EMAIL=test1@example.com
rails panda:core:users:delete EMAIL=test2@example.com

# Verify cleanup
rails panda:core:users:list
```

## Integration with OAuth

These tasks work seamlessly with the OAuth authentication system:

1. **Auto-Provisioning**: When a user logs in via OAuth for the first time, their account is automatically created
2. **Admin Management**: Use these tasks to grant/revoke admin privileges after OAuth auto-provisioning
3. **First User**: The very first user created (either via OAuth or `create_admin`) automatically gets admin privileges

**Typical Flow:**
```bash
# 1. User visits /admin/login and authenticates via Google/GitHub
# 2. User account is auto-created (admin: false)
# 3. Admin grants privileges via Rake task
rails panda:core:users:grant_admin EMAIL=newuser@company.com
# 4. User can now access admin features
```

## Best Practices

### Security

1. **Protect Task Access**: Only run these tasks in secure environments (production console, VPN, etc.)
2. **Audit Trail**: Consider logging admin privilege changes for compliance
3. **Principle of Least Privilege**: Only grant admin access when necessary
4. **Regular Reviews**: Periodically review admin users and revoke unnecessary access

### Development

1. **Use Developer Strategy**: In development, use the OmniAuth developer strategy instead of real OAuth credentials
2. **Seed Data**: Add admin user creation to your `db/seeds.rb` for consistent test data
3. **Test Coverage**: Test both admin and non-admin user scenarios

### Production

1. **Multiple Admins**: Always maintain at least 2 admin users to prevent lockout
2. **Document Admins**: Keep a record of who should have admin access
3. **Offboarding**: Remember to revoke admin access when team members leave
4. **Emergency Access**: Have a documented process for creating admins if all are locked out

## Troubleshooting

### "No route matches /admin"

**Problem**: Accessing admin routes returns 404

**Solution**: Ensure you're logged in as an admin user. Check status with:
```bash
rails panda:core:users:list
```

### "Cannot revoke admin privileges from the last admin user"

**Problem**: Trying to remove admin access but only one admin exists

**Solution**: Create or promote another admin first:
```bash
rails panda:core:users:grant_admin EMAIL=another@example.com
# Then revoke from the original user
rails panda:core:users:revoke_admin EMAIL=original@example.com
```

### "User with email 'user@example.com' not found"

**Problem**: User doesn't exist in the database yet

**Solutions:**
1. User needs to log in via OAuth first (auto-creates account)
2. Or create the user manually:
   ```bash
   rails panda:core:users:create_admin EMAIL=user@example.com
   ```

### Task Not Found

**Problem**: `rails panda:core:users:list` returns "Don't know how to build task"

**Solution**: The tasks are defined in panda-core's lib/tasks directory. Ensure:
1. panda-core is in your Gemfile
2. You've run `bundle install`
3. You're running the task from your application root

## See Also

- [Authentication Providers](providers.md) - Configure OAuth providers
- [Authentication Testing](../quick-start/authentication-testing.md) - Testing with authentication
- [Migration Guide](migration.md) - Migrating from panda-cms authentication
