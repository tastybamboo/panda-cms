# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For comprehensive developer documentation, see the `docs/` directory which contains detailed guides on testing, configuration, deployment, and development practices.

## Project Overview

Panda CMS is a Rails engine that provides content management functionality for Rails applications. It's built as a gem and follows the Rails Engine architecture pattern. The project uses modern Rails features and focuses on developer experience.

**Important**: This project depends on `panda-core` gem which is located at `../core` in development. The Gemfile uses a local path reference for development and testing.

## Architecture

### Engine Structure
- **Rails Engine**: Panda CMS is implemented as a Rails Engine in `lib/panda/cms/engine.rb`
- **Namespaced Models**: All models are under `Panda::CMS` namespace in `app/models/panda/cms/`
- **View Components**: Uses ViewComponent pattern for reusable UI components in `app/components/panda/cms/`
- **EditorJS Integration**: Custom content editor system with blocks in `lib/panda/cms/editor_js/`

### Key Directories
- `app/` - Standard Rails app structure but namespaced under `panda/cms/`
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
- Configuration in engine initializers

## Development Setup

### Panda-Core Gem Dependency
The project depends on the panda-core gem for user authentication:
- **Gemfile reference**: Use `gem "panda-core", github: "tastybamboo/panda-core", branch: "main"` (works for both local and CI)
- **Local development override**: Use `bundle config local.panda-core /absolute/path/to/panda-core` to use your local checkout
  - This allows testing local changes without modifying the Gemfile
  - Requires absolute path, not relative (e.g., `/Users/james/Projects/panda/core`)
  - To remove: `bundle config --delete local.panda-core`
  - Current setting: Already configured to use `/Users/james/Projects/panda/core`
- **Important**: The GitHub reference in Gemfile ensures CI can build without local paths

## Development Commands

### Testing

#### Test Asset Preparation

**Asset Architecture:**

- **JavaScript**: Uses importmaps (no compilation needed) - individual ES modules served via JavaScriptMiddleware
- **CSS**: Compiled by panda-core for all Panda modules via `bundle exec rake app:panda:compile_css`
- **Propshaft Assets**: Prepared automatically by panda-assets-verify-action in CI

**For Local Development:**

No special asset preparation is required before running tests. Assets are:

- JavaScript files served directly from `app/javascript/panda/cms/` via importmap
- CSS pre-compiled and committed to panda-core's `public/panda-core-assets/` directory
- If you modify Tailwind classes, run `bundle exec rake app:panda:compile_css` to update CSS

**For CI:**

The panda-assets-verify-action automatically prepares Propshaft assets before tests run.

#### CSS Compilation Behavior

**Important**: Always compile CSS from the highest-level Panda project (e.g., panda-cms, not panda-core):

- **Why**: Tailwind CSS v4 performs aggressive tree-shaking based on ALL scanned files
- **Effect**: Compiling from panda-cms (which scans core + cms files) produces a smaller, more optimized CSS file (~50 KB minified) compared to compiling from panda-core alone (~72 KB minified)
- **Reason**: When scanning only panda-core files, Tailwind includes utilities that MIGHT be used by unknown consumers. When scanning all modules together, it knows exactly what's used and removes unused utilities (e.g., unused color variables, container sizes, font weights, and margin utilities like `m-23`, `m-171`, etc.)

This is correct behavior - the smaller file from panda-cms is properly optimized for your actual usage.

#### Running Tests
```bash
# IMPORTANT: Always run tests from the project root directory (/Users/james/Projects/panda-cms)
# NOT from spec/dummy/ directory

# Run all tests
bundle exec rspec

# Run tests with focus/exclusions
bundle exec rspec --tag ~skip

# Run specific test types
bundle exec rspec spec/models/
bundle exec rspec spec/system/
bundle exec rspec spec/lib/

# Run single test file
bundle exec rspec spec/models/panda/cms/page_spec.rb

# Run specific test by name pattern
bundle exec rspec spec/system/panda/cms/admin/posts/add_post_spec.rb -e "shows validation errors when title is missing"

# Run specific test by line number
bundle exec rspec spec/system/panda/cms/admin/posts/add_post_spec.rb:106

# Include EditorJS tests (excluded by default)
INCLUDE_EDITORJS=true bundle exec rspec

# Categorize test failures from output
bundle exec rspec 2>&1 | tee /tmp/test_output.txt
bin/categorize_test_failures /tmp/test_output.txt

# Or pipe directly
bundle exec rspec | bin/categorize_test_failures

# Enable debug output in tests (gated by RSPEC_DEBUG)
RSPEC_DEBUG=true bundle exec rspec
```

### Code Quality
```bash
# Run StandardRB linter
bundle exec standardrb

# Run Brakeman security scanner
bundle exec brakeman --quiet

# Run ERB linting
bundle exec erb_lint app/views --lint-all

# Run bundle audit
bundle exec bundle-audit --update

# Run YAML linter
yamllint -c .yamllint .
```

### Asset Management

#### CSS Compilation

**Important:** CSS for panda-cms is compiled via **panda-core**, not within panda-cms itself.

panda-cms registers its view paths with panda-core's ModuleRegistry during engine initialization. When `rake app:panda:compile_css` runs (from any Panda gem), it:

1. Discovers all registered Panda modules (core, cms, cms-pro, etc.)
2. Scans their registered paths for Tailwind classes
3. Compiles everything into `panda-core/public/panda-core-assets/panda-core.css`

**To compile CSS including panda-cms classes:**
```bash
# From panda-cms directory
bundle exec rake app:panda:compile_css

# This outputs CSS to panda-core, not panda-cms
# Result: panda-core/public/panda-core-assets/panda-core.css
```

**Why panda-cms/public/panda-core-assets/ is empty:**
This is expected! panda-cms doesn't generate its own CSS file. All Panda ecosystem CSS is consolidated in panda-core for:
- Reduced HTTP requests
- Consistent styling across modules
- Single source of truth for design system

**CSS Changes During Development:**
- Modify Tailwind classes in panda-cms components/views
- Run `bundle exec rake app:panda:compile_css`
- CSS is updated in panda-core automatically
- Host apps load the updated panda-core CSS

#### Development
```bash
# Start development server (uses importmaps)
bin/dev
```

#### JavaScript Architecture

**Important:** panda-cms uses an **importmap-based architecture** with individual ES modules. JavaScript is NOT compiled - files are served directly from `app/javascript/panda/cms/`.

**How it works:**
1. JavaScript files are registered with ModuleRegistry during engine initialization
2. Custom JavaScriptMiddleware intercepts `/panda/cms/*` requests
3. Browser loads individual ES modules via importmap
4. No build step, webpack, or bundling required

**File structure:**
```
app/javascript/panda/cms/
├── application.js          # Main entry point
└── controllers/            # Stimulus controllers (individual files)
    ├── post_controller.js
    ├── page_controller.js
    └── ...
```

**Importmap configuration** (`config/importmap.rb`):
```ruby
pin "panda/cms/application", to: "/panda/cms/application.js"
pin_all_from Panda::CMS::Engine.root.join("app/javascript/panda/cms/controllers"),
             under: "controllers", to: "/panda/cms/controllers"
```

**Benefits:**
- No JavaScript compilation needed during development
- Individual file caching by browser
- Simpler debugging (no source maps needed)
- Consistent with panda-core and other Panda gems

**Legacy Note:** Old rake tasks like `panda_cms:assets:compile` and references to compiled bundles are obsolete. The current architecture does not create or use JavaScript bundles.

### Database
```bash
# Run migrations in dummy app
cd spec/dummy && rails db:migrate

# Generate missing blocks from templates
bundle exec rake panda:cms:generate_missing_blocks

# Export data as JSON
bundle exec rake panda:cms:export:json
```

### Development Server
```bash
# Start with Procfile (recommended for development)
bin/dev

# This starts:
# - Rails server on port 3000
# - Asset watching for admin styles
```

## Testing Strategy

### Test Structure
- Uses RSpec with fixtures instead of factories (with exceptions below)
- Fixtures in `spec/fixtures/` with YAML format
- System tests use Cuprite (Chrome headless) for browser automation
- EditorJS tests are excluded by default (use `INCLUDE_EDITORJS=true` to include)

### User and Post Testing (IMPORTANT)
- **Users are created programmatically**, NOT via fixtures (panda_core_users table is in another gem)
- **Posts in fixtures have NULL user references** - tests must set them when needed
- **User references are nullable** - user_id and author_id columns allow NULL in panda_cms_posts
- See `spec/TEST_WRITING_GUIDE.md` for detailed patterns and CI considerations
- Use `create_admin_user` and `create_regular_user` helper methods
- These helpers use fixed IDs for consistent references:
  - Admin: `8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a`
  - Regular: `9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d`

**Common pattern for tests with posts:**
```ruby
before do
  @admin = create_admin_user
  panda_cms_posts(:first_post).update!(user: @admin, author: @admin)
end
```

### Validation Tests
- **Important**: See `docs/developers/testing/validation-testing.md` for complete validation testing patterns
- Validation tests are automatically detected by test description keywords
- Require clean page state with `visit` at start of each test
- Must include `expect(page).to have_css("form", wait: 5)` for form readiness
- Use exact validation error messages from models (e.g., "Title can't be blank")

### Fixture Usage
```ruby
# Access fixtures using table name and record name
page = panda_cms_pages(:home_page)
user = panda_cms_users(:admin_user)
```

### System Test Helpers
- `spec/support/cuprite_helper_methods.rb` - Browser automation helpers
- `spec/support/editor_helpers.rb` - EditorJS testing utilities  
- `spec/support/omni_auth_helpers.rb` - Authentication test helpers

## Configuration

### Engine Configuration
- Primary config in `config/initializers/panda/cms.rb`
- Authentication providers configured in engine initializer
- EditorJS tools and configuration customizable via Panda::Editor (see `config/initializers/panda_editor.rb`)

### Asset Distribution
- Static assets served from `public/panda-cms-assets/`
- JavaScript modules in `app/javascript/panda/cms/`
- Stimulus controllers for interactive behavior

## Code Patterns

### Model Conventions
- All models inherit from `Panda::CMS::ApplicationRecord`
- Use UUIDs as primary keys (configured in generator settings)
- Nested set pattern for hierarchical data (pages, menus)
- EditorJS content stored as JSON with cached HTML rendering

### View Component Pattern
- Components in `app/components/panda/cms/`
- Admin-specific components in `app/components/panda/cms/admin/`
- Each component has `.rb` class and `.html.erb` template

### Service Objects
- Services in `app/services/panda/cms/`
- Handle complex business logic (HTML conversion, content processing)

### EditorJS Integration
- Block types in `lib/panda/cms/editor_js/blocks/`
- Renderer in `lib/panda/cms/editor_js/renderer.rb`
- Custom JavaScript in panda-editor gem (`app/javascript/panda/editor/`)

## Troubleshooting

### JavaScript Issues

**Current Architecture:** panda-cms uses importmaps with individual ES modules (no compilation/bundling).

#### Common Symptoms
- System tests timing out waiting for JavaScript
- Stimulus controllers not registering
- "Could not find node with given id" errors in Capybara tests
- Tests work locally but fail in CI

#### Solutions

**Problem: JavaScript Files Not Loading**

1. Verify importmap configuration in `config/importmap.rb`
2. Check that JavaScriptMiddleware is serving files from `/panda/cms/` paths
3. Ensure ModuleRegistry has registered panda-cms JavaScript paths during engine initialization

**Problem: Stimulus Controllers Not Registering**

- Verify controller files exist in `app/javascript/panda/cms/controllers/`
- Check browser console for import errors
- Ensure controllers are properly exported as default exports

**Problem: Tests Fail in CI but Pass Locally**

- Check that panda-assets-verify-action has run successfully in CI
- Verify Propshaft assets were prepared for the test environment
- Check GitHub Actions logs for asset middleware errors

#### Verification Steps

1. **Check importmap is loaded**:
   ```bash
   # In Rails console
   Rails.application.config.importmap.draw
   ```

2. **Verify JavaScript files are accessible**:
   ```bash
   curl http://localhost:3000/panda/cms/application.js
   # Should return the JavaScript file content
   ```

3. **Check ModuleRegistry**:
   ```bash
   bundle exec rake app:panda:registered_modules
   # Should list panda-cms with JavaScript paths
   ```

## Security Guidelines

### Permission Checks: Deny by Default
When adding authorization checks (via `can?`, `authorized_for?`, or similar), always default to **deny** when the authorization system is unavailable. Never return `true` as a fallback:

```ruby
# WRONG — fails open, bypasses security if can? isn't available
return true unless view_context.respond_to?(:can?)

# CORRECT — fails closed, denies access if can? isn't available
return false unless view_context.respond_to?(:can?)
```

### Nested Resource Scoping
When a route nests a child resource under a parent (e.g., `pages/:page_id/block_contents/:id`), always load the child **through the parent association**, not via a global `find`. This prevents cross-resource attacks where an attacker supplies a valid child ID that belongs to a different parent:

```ruby
# WRONG — allows cross-page block content manipulation
@block_content = Panda::CMS::BlockContent.find(params[:id])

# CORRECT — scoped to the parent, raises RecordNotFound for mismatches
@block_content = @page.block_contents.find(params[:id])
```

### Raw HTML Components
The `CodeComponent` renders raw HTML/JS by design (for widgets, analytics, etc.). Any component that uses `raw()` or `.html_safe()` must have explicit permission checks. Use the `:edit_code_blocks` permission pattern — admin users bypass all checks, non-admin users need explicit grants.

## Important Notes

- The gem is in active development and not production-ready
- Uses fixtures for consistent test data instead of factories
- System tests capture screenshots on failure in `tmp/capybara/`
- Authentication requires provider setup (GitHub, Google, Microsoft)
- Database schema uses UUIDs for all primary keys
- Content is stored as EditorJS JSON with cached HTML rendering

## Workflow Memories

- You should always download artifacts once I tell you a CI run is complete, and add the working directories you need automatically, it saves me doing it manually.
- Remember to do this whenever we're debugging CI runs so I don't have to keep doing this work manually. We should also end the CI run early, if we find any failures.
- Always allow adding the tmp/ci-artifacts* directory it needs
- **Always monitor CI runs if we're trying to debug them for this project**

## Code Quality Memories
- Always run "yamllint -c .yamllint ." if you make changes to .yml or .yaml files.

## PR Readiness Checker Agent
- Use the `pr-readiness-checker` agent when preparing to raise pull requests
- The agent validates code changes, runs tests, checks linting, and ensures CI requirements are met
- **Important**: The agent should always merge in the latest main branch before pushing changes
- This agent helps prevent CI failures by running equivalent checks locally first