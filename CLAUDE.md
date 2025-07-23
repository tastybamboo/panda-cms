# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

# 2. Compile assets for the current codebase
bundle exec rake app:panda_cms:assets:compile

# 3. Commit the compiled assets
git add public/panda-cms-assets/
git commit -m "Compile assets for release"

# 4. Create and push release tag
git tag -a v0.X.Y -m "Release v0.X.Y"
git push origin main --tags

# 5. Upload assets to GitHub release
bundle exec rake app:panda_cms:assets:upload
```

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

## Important Notes

- The gem is in active development and not production-ready
- Uses fixtures for consistent test data instead of factories
- System tests capture screenshots on failure in `tmp/capybara/`
- Authentication requires provider setup (GitHub, Google, Microsoft)
- Database schema uses UUIDs for all primary keys
- Content is stored as EditorJS JSON with cached HTML rendering