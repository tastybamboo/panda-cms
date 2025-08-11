# User Migration from Panda CMS to Panda Core

## Overview

This document describes the migration of user authentication from panda-cms to panda-core gem, completed on August 11, 2025.

**Latest Fix**: Fixed panda-core sidebar template to use `configuration` instead of `config` (commit 9400378).

## Why This Migration?

1. **Separation of Concerns**: Authentication should be in a core gem, not the CMS
2. **Reusability**: Other panda-* gems can use the same authentication
3. **Maintainability**: Centralized user management and authentication logic

## What Changed

### Database Changes

1. **Users moved to panda_core_users table** (managed by panda-core gem)
   - Migration: `20250809231125_migrate_users_to_panda_core.rb`
   - Copies data from panda_cms_users to panda_core_users
   - Updates foreign keys to reference new table

2. **Post user references made nullable** 
   - Migration: `20250811111000_make_post_user_references_nullable.rb`
   - Makes user_id and author_id columns nullable in panda_cms_posts
   - Required for fixtures to work without user references

### Code Changes

1. **User model moved to panda-core**
   - Was: `Panda::CMS::User`
   - Now: `Panda::Core::User`

2. **Authentication controllers moved to panda-core**
   - Was: `Panda::CMS::Admin::SessionsController`
   - Now: `Panda::Core::Admin::SessionsController`

3. **Current attributes moved to panda-core**
   - Was: `Panda::CMS::Current`
   - Now: `Panda::Core::Current`

### Testing Changes

1. **No user fixtures** - Users are created programmatically
2. **Post fixtures have no users** - Tests must set user references
3. **Helper methods** - `create_admin_user` and `create_regular_user`
4. **Fixed user IDs** - Consistent IDs for testing

## Migration Approach

We chose **Option #3: Programmatic User Creation** from three possible approaches:

### Options Considered

1. **Option 1**: Keep fixtures, modify migrations to use view/synonym
   - ❌ Too complex, Rails doesn't handle view fixtures well
   
2. **Option 2**: Create column aliases in User model
   - ❌ Rails caching issues, fixture loader ignores aliases
   
3. **Option 3**: Move away from user fixtures ✅
   - ✅ Most flexible
   - ✅ Works with Rails fixture system
   - ✅ Avoids cross-gem dependency issues

## Implementation Details

### User Column Mapping

The panda-core User model uses these columns:
- `firstname` (not `name`)
- `lastname` (not `name`)
- `admin` (boolean, not `is_admin`)
- `email`
- `image_url`

The model provides a `name` method that returns `"#{firstname} #{lastname}"`.

### Test Helper Methods

```ruby
# In spec/support/user_helpers.rb

# Creates admin user with fixed ID
create_admin_user(
  email: "admin@example.com",    # optional override
  firstname: "Admin",             # optional override
  lastname: "User"               # optional override
)

# Creates regular user with fixed ID  
create_regular_user(
  email: "user@example.com",     # optional override
  firstname: "Regular",          # optional override
  lastname: "User"              # optional override
)
```

### Fixed IDs for Testing

- Admin user: `8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a`
- Regular user: `9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d`

These IDs are consistent across all tests and can be referenced in fixtures if needed.

## CI Considerations

### Bundle Configuration

- **Local development**: Use `path: "../core"` for panda-core gem
- **CI/Production**: Use `github: "tastybamboo/panda-core", branch: "..."`

### Foreign Key Constraints

CI cannot handle foreign key references to panda_core_users because:
1. The table is in another gem
2. Fixtures load before users can be created
3. Rails doesn't understand the cross-gem dependency

Solution: Make user references nullable and set them in tests.

## Common Issues and Solutions

### Issue: "undefined method 'name=' for Panda::Core::User"

**Cause**: Using wrong column name  
**Solution**: Use `firstname` and `lastname` instead of `name`

### Issue: Foreign key violations in fixtures

**Cause**: Fixtures trying to reference non-existent users  
**Solution**: Remove user references from fixtures, set them in tests

### Issue: "undefined method 'is_admin' for User"

**Cause**: Column is `admin`, not `is_admin`  
**Solution**: Use `admin?` method or `admin` column directly

## Testing Patterns

### Pattern 1: Test with existing post fixture

```ruby
RSpec.describe "Something", type: :system do
  fixtures :panda_cms_posts
  
  before do
    @admin = create_admin_user
    # Update fixture post to have user
    panda_cms_posts(:first_post).update!(user: @admin, author: @admin)
    login_as_admin
  end
end
```

### Pattern 2: Create post programmatically

```ruby
RSpec.describe "Something", type: :system do
  before do
    @admin = create_admin_user
    @post = Panda::CMS::Post.create!(
      title: "Test",
      user: @admin,
      author: @admin,
      # ... other attributes
    )
    login_as_admin
  end
end
```

## Files Changed

### Key Files Modified
- `Gemfile` - Updated panda-core reference
- `spec/rails_helper.rb` - Excluded user/post fixtures from global loading
- `spec/fixtures/panda_cms_posts.yml` - Removed user references
- `spec/support/user_helpers.rb` - Created helper methods
- `spec/models/panda/cms/user_spec.rb` - Updated to use correct columns
- Multiple migration files - Handle table transitions

### Files Removed
- `spec/fixtures/panda_core_users.yml` - No longer needed
- `spec/support/fixtures_setup.rb` - Caused CI issues

### Files Added
- `spec/TEST_WRITING_GUIDE.md` - Comprehensive testing guide
- `MIGRATION_NOTES.md` - This file

## Rollback Plan

If you need to rollback this migration:

1. Revert the commits from the feature branch
2. Run rollback migration to restore panda_cms_users
3. Update Gemfile to remove panda-core dependency
4. Restore original User model in panda-cms
5. Update all references back to Panda::CMS::User

## Future Considerations

1. **Complete the panda-core extraction** - Move remaining auth components
2. **Update production deployments** - Ensure panda-core gem is available
3. **Document API changes** - For apps using panda-cms
4. **Consider data migration tools** - For production systems

## References

- Original PR: [#103](https://github.com/tastybamboo/panda-cms/pull/103)
- Panda Core PR: [Link to panda-core PR]
- Related Issue: [Link to issue if exists]
- Test Writing Guide: `spec/TEST_WRITING_GUIDE.md`