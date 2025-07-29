# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For comprehensive developer documentation, see the `docs/` directory which contains detailed guides on testing, configuration, deployment, and development practices.

## Project Overview

Panda CMS is a Rails engine that provides content management functionality for Rails applications. It's built as a gem and follows the Rails Engine architecture pattern. The project uses modern Rails features and focuses on developer experience.

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

## Development Commands

### Testing
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

#### Development
```bash
# Start development server (uses importmaps)
bin/dev
```

#### Production Asset Compilation
```bash
# Compile Panda CMS assets for production/testing
bundle exec rake app:panda_cms:assets:compile

# Upload compiled assets to GitHub release (for distribution)
bundle exec rake app:panda_cms:assets:upload

# Download production assets from GitHub release
bundle exec rake app:panda_cms:assets:download
```

**Enhanced Asset Compilation Features:**
- Automatically compiles all Stimulus controllers from `app/javascript/panda/cms/controllers/`
- Generates functional standalone JavaScript bundles with working controller implementations
- Copies compiled assets to test environment location (`spec/dummy/public/panda-cms-assets/`)
- Creates enhanced controllers with proper slug generation, form handling, and alert management
- Includes proper initialization code with `window.pandaCmsStimulus` compatibility
- Supports both root-level and versioned directory asset placement for CI compatibility

#### When to Compile Assets
Asset compilation is required when:
- **JavaScript changes**: Any modifications to Stimulus controllers or JS modules
- **CSS changes**: Updates to styles or TailwindCSS configurations  
- **Creating releases**: Before tagging and publishing new versions
- **Testing failures**: When system tests fail due to missing JavaScript functionality
- **CI/Production deployment**: Ensuring consistent assets across environments

#### Release Process with Assets
```bash
# 1. Make your code changes
git add . && git commit -m "Your changes"

# 2. Create and push release tag
git tag -a v0.X.Y -m "Release v0.X.Y"
git push origin main --tags

# 3. GitHub Actions automatically compiles and uploads assets
# Monitor the release workflow at:
# https://github.com/tastybamboo/panda-cms/actions/workflows/release-assets.yml

# 4. Once assets are uploaded, publish the gem
gem build panda-cms.gemspec
gem push panda-cms-0.X.Y.gem
```

**Note**: Assets are automatically compiled and uploaded by the GitHub Actions workflow when a release tag is pushed. For manual asset compilation, see the [release documentation](docs/developers/releasing.md).

#### Asset Loading Strategy
Panda CMS uses different asset loading strategies based on environment:

**Development Environment:**
- Uses **importmaps** with individual ES modules
- JavaScript loaded from `app/javascript/panda/cms/` 
- Supports hot reloading and individual debugging
- No compilation required

**Test Environment:**
- Uses **compiled bundles** from `public/panda-cms-assets/`
- Ensures consistent JavaScript functionality for system tests
- Requires asset compilation when JavaScript changes
- Automatically generated during CI asset compilation step

**Production Environment:**
- Downloads **compiled bundles** from GitHub releases
- Single minified files with integrity checks
- Cached locally for performance
- CDN distribution via GitHub releases

**Environment Override:**
```bash
# Force production assets in any environment
PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec rails server
```

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
- Uses RSpec with fixtures instead of factories
- Fixtures in `spec/fixtures/` with YAML format
- System tests use Cuprite (Chrome headless) for browser automation
- EditorJS tests are excluded by default (use `INCLUDE_EDITORJS=true` to include)

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
- EditorJS tools and configuration customizable via `config.editor_js_tools`

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
- Custom JavaScript in `app/javascript/panda/cms/editor/`

## Troubleshooting

### JavaScript Asset Compilation Issues

If you encounter JavaScript test failures with errors like "Could not find node with given id" or debug output showing `pandaCmsLoaded: nil`, this indicates JavaScript asset compilation or loading problems.

#### Common Symptoms
- System tests timing out waiting for JavaScript
- Debug output shows: `{"pandaCmsLoaded" => nil, "stimulusExists" => false}`
- "Could not find node with given id" errors in Capybara tests
- Tests work locally but fail in CI

#### Root Causes and Solutions

**Problem 1: Asset Compilation Task Not Running in CI**
```bash
# In CI, assets are compiled from the spec/dummy directory
cd spec/dummy
bundle exec rake panda_cms:assets:compile  # Correct for CI

# For local development from project root
bundle exec rake app:panda_cms:assets:compile  # Correct for local dev
```

**Problem 2: Assets Generated but Not Copied to Test Location**
The asset compilation task automatically copies compiled assets from `tmp/panda_cms_assets/` to `spec/dummy/public/panda-cms-assets/` for test environment use. If tests still fail:
```bash
# Verify assets were copied correctly
ls -la spec/dummy/public/panda-cms-assets/
# Should show panda-cms-0.7.4.js and panda-cms-0.7.4.css
```

**Problem 3: Asset Loading Strategy Mismatch**
In test environment, the system should use compiled bundles, not importmap. Check the debug output for:
```
[Panda CMS Test] Asset strategy: GitHub/Compiled  # Correct
[Panda CMS Test] Asset strategy: Development/Local  # Incorrect in test
```

**Problem 4: Wrong Script Type for Standalone Bundles**
Standalone bundles should NOT use `type="module"`. The AssetLoader automatically detects bundle type and applies correct script attributes.

**Problem 5: Missing Required JavaScript Variables**
Enhanced bundles must include:
- `window.pandaCmsLoaded = true`
- `window.pandaCmsStimulus = window.Stimulus`
- `window.pandaCmsVersion`
- Functional Stimulus controllers

#### Verification Steps
1. **Check asset compilation output**:
   ```bash
   bundle exec rake app:panda_cms:assets:compile
   # Should show: "Found controller files: [...]" with actual file paths
   # Should show: "✅ Copied JavaScript to test location"
   ```

2. **Verify bundle content**:
   ```bash
   grep -c "pandaCmsLoaded" spec/dummy/public/panda-cms-assets/panda-cms-*.js
   grep -c "Stimulus.register" spec/dummy/public/panda-cms-assets/panda-cms-*.js
   # Both should return counts > 0
   ```

3. **Check test environment asset loading**:
   ```bash
   # Run a single system test and check debug output
   bundle exec rspec spec/system/panda/cms/admin/posts/add_post_spec.rb:15
   # Look for: [Panda CMS Test] JavaScript URL: /panda-cms-assets/panda-cms-*.js
   ```

#### CI-Specific Issues
- Ensure working directory is `spec/dummy` when running asset compilation
- Verify engine controller files are accessible in CI environment
- Check that compiled assets have correct file permissions (should be readable)

### System Test Debug Information
System tests automatically output debug information when JavaScript fails to load:
```
[Test Debug] Asset state: {
  "pandaCmsLoaded" => true,     # Should be true
  "stimulusExists" => true,     # Should be true  
  "controllerCount" => 5,       # Should be > 0
  "pandaCmsFullBundle" => true  # Should be true
}
```

If any of these values are `nil` or `false`, the JavaScript bundle is not executing properly.

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