# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

**Parent:** See the monorepo-wide [CLAUDE.md](../CLAUDE.md) for rules on CSS compilation, JS architecture, API security, ViewComponent requirements, and the PR readiness checker.

For comprehensive developer documentation, see the `docs/` directory which contains detailed guides on testing, configuration, deployment, and development practices.

## Project Overview

Panda CMS is a Rails engine that provides content management functionality for Rails applications. It's built as a gem and follows the Rails Engine architecture pattern.

**Important**: This project depends on the `panda-core` gem. The Gemfile references `panda-core` from GitHub, and for local monorepo development the source lives at `../core` and is typically wired in via `bundle config local.panda-core` (see the "Panda-Core Gem Dependency" section below).

## Architecture

### Engine Structure
- **Rails Engine**: `lib/panda/cms/engine.rb`
- **Namespaced Models**: All models under `Panda::CMS` namespace in `app/models/panda/cms/`
- **View Components**: Uses ViewComponent pattern in `app/components/panda/cms/`
- **EditorJS Integration**: Custom content editor system with blocks in `lib/panda/cms/editor_js/`

### Key Directories
- `app/` - Standard Rails app structure namespaced under `panda/cms/`
- `lib/panda/cms/` - Core engine functionality, configuration, and services
- `spec/` - Test suite using RSpec
- `spec/dummy/` - Test Rails application for development/testing
- `public/panda-cms-assets/` - Static assets distributed with the gem

### Content Management
- **Pages**: Hierarchical content structure with nested sets
- **Posts**: Blog-style content with EditorJS content
- **Templates**: Reusable page layouts with blocks
- **Blocks**: Content components (paragraphs, headers, images, etc.)
- **Menus**: Navigation management
- **Forms**: Contact forms with submission handling

### Authentication
- Uses OmniAuth with support for GitHub, Google, and Microsoft providers
- User management with admin roles

## Development Setup

### Panda-Core Gem Dependency
- **Gemfile reference**: Use `gem "panda-core", github: "tastybamboo/panda-core", branch: "main"`
- **Local development override**: Use `bundle config local.panda-core /absolute/path/to/panda-core`
  - To remove: `bundle config --delete local.panda-core`
  - Example setting: `bundle config local.panda-core /path/to/panda/core`
- **Important**: The GitHub reference in Gemfile ensures CI can build without local paths

## Development Commands

### Testing

**IMPORTANT**: Always run tests from the project root directory, NOT from spec/dummy/.

```bash
bundle exec rspec                    # Run all tests
bundle exec rspec --tag ~skip        # Exclude skipped tests
bundle exec rspec spec/models/       # Run specific test type
bundle exec rspec spec/models/panda/cms/page_spec.rb       # Single file
bundle exec rspec spec/system/... -e "test name"           # By name
bundle exec rspec spec/system/...:106                      # By line number
INCLUDE_EDITORJS=true bundle exec rspec                    # Include EditorJS tests
RSPEC_DEBUG=true bundle exec rspec                         # Debug output
```

### Code Quality
```bash
bundle exec standardrb              # StandardRB linter
bundle exec brakeman --quiet        # Security scanner
bundle exec erb_lint app/views --lint-all  # ERB linting
bundle exec bundle-audit --update   # Bundle audit
yamllint -c .yamllint .             # YAML linter
```

### Database
```bash
cd spec/dummy && rails db:migrate   # Run migrations in dummy app
bundle exec rake panda:cms:generate_missing_blocks  # Generate missing blocks
bundle exec rake panda:cms:export:json              # Export data as JSON
```

## Testing Strategy

### Test Structure
- Uses RSpec with fixtures instead of factories (with exceptions below)
- Fixtures in `spec/fixtures/` with YAML format
- System tests use Cuprite (Chrome headless) for browser automation
- EditorJS tests are excluded by default (use `INCLUDE_EDITORJS=true`)

### User and Post Testing (IMPORTANT)
- **Users are created programmatically**, NOT via fixtures (panda_core_users table is in another gem)
- **Posts in fixtures have NULL user references** — tests must set them when needed
- Use `create_admin_user` and `create_regular_user` helper methods
- These helpers use fixed IDs for consistent references
- See `spec/TEST_WRITING_GUIDE.md` for detailed patterns

**Common pattern for tests with posts:**
```ruby
before do
  @admin = create_admin_user
  panda_cms_posts(:first_post).update!(user: @admin, author: @admin)
end
```

### Validation Tests
- See `docs/developers/testing/validation-testing.md` for complete patterns
- Require clean page state with `visit` at start of each test
- Must include `expect(page).to have_css("form", wait: 5)` for form readiness
- Use exact validation error messages from models

### System Test Helpers
- `spec/support/cuprite_helper_methods.rb` - Browser automation helpers
- `spec/support/editor_helpers.rb` - EditorJS testing utilities
- `spec/support/omni_auth_helpers.rb` - Authentication test helpers

## Security Guidelines

### Permission Checks: Deny by Default
```ruby
# WRONG — fails open
return true unless view_context.respond_to?(:can?)

# CORRECT — fails closed
return false unless view_context.respond_to?(:can?)
```

### Nested Resource Scoping
```ruby
# WRONG — allows cross-page manipulation
@block_content = Panda::CMS::BlockContent.find(params[:id])

# CORRECT — scoped to parent
@block_content = @page.block_contents.find(params[:id])
```

### Raw HTML Components
The `CodeComponent` renders raw HTML/JS by design. Any component that uses `raw()` or `.html_safe()` must have explicit permission checks. Use the `:edit_code_blocks` permission pattern.

## Troubleshooting

### CI Debugging
- Always download artifacts once a CI run is complete (add the `tmp/ci-artifacts*` directory automatically)
- End CI runs early if failures are found
- Always monitor CI runs when debugging them for this project

### JavaScript Issues
- panda-cms uses importmaps with individual ES modules (no compilation/bundling)
- System tests timing out → check importmap configuration and JavaScriptMiddleware
- Stimulus controllers not registering → verify files exist in `app/javascript/panda/cms/controllers/`
- Tests fail in CI but pass locally → check panda-assets-verify-action ran successfully

## Important Notes

- The gem is in active development and not production-ready
- Uses fixtures for consistent test data instead of factories
- System tests capture screenshots on failure in `tmp/capybara/`
- Authentication requires provider setup (GitHub, Google, Microsoft)
- Database schema uses UUIDs for all primary keys
- Content is stored as EditorJS JSON with cached HTML rendering
