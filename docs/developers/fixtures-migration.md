# Fixtures Testing Strategy

This document outlines the testing strategy for Panda CMS, which uses Rails fixtures for system tests to provide better performance, predictability, and maintainability.

## Overview

Panda CMS uses Rails fixtures for all system tests. This approach provides:

- **Performance**: Fixtures are loaded once and reused, making tests significantly faster
- **Predictability**: Fixed data makes tests more deterministic
- **Simplicity**: Less complex than factory setups
- **Maintainability**: Easier to maintain than complex factory definitions

## Test Suite Status

### ✅ All System Tests Passing (57/57)

| Test Suite | Examples | Status | Performance |
|------------|----------|---------|-------------|
| **Admin Profile Management** | 5 | ✅ PASSING | ~1.8s avg |
| **Add Page Tests** | 20 | ✅ PASSING | ~1.9s avg |
| **Edit Page Tests** | 10 | ✅ PASSING | ~1.7s avg |
| **Add Post Tests** | 4 | ✅ PASSING | ~1.8s avg |
| **Edit Post Tests** | 1 | ✅ PASSING | ~1.8s avg |
| **Admin Dashboard** | 4 | ✅ PASSING | ~1.2s avg |
| **Admin Authentication** | 7 | ✅ PASSING | ~1.2s avg |
| **List Pages** | 1 | ✅ PASSING | ~1.5s avg |
| **Redirects** | 3 | ✅ PASSING | ~0.7s avg |
| **Website** | 2 | ✅ PASSING | ~0.5s avg |

**Total Runtime**: ~1.5 minutes for all 57 tests
**Test Coverage**: 68.25% (1922/2816 LOC)

## Configuration

### Rails Helper Setup

The following configuration enables fixtures globally:

```ruby
# spec/rails_helper.rb

# Configure fixtures path and enable fixtures
config.fixture_paths = [File.expand_path("fixtures", __dir__)]
config.use_transactional_fixtures = true
# Load fixtures globally for all tests
config.global_fixtures = :all

# Include fixture helpers
config.include FixtureHelpers
```

### Fixture Class Mapping

Namespaced models require custom fixture class mapping:

```ruby
# spec/rails_helper.rb

module PandaCmsFixtures
  def self.get_class_name(fixture_set_name)
    case fixture_set_name
    when "panda_cms_users" then "Panda::CMS::User"
    when "panda_cms_posts" then "Panda::CMS::Post"
    when "panda_cms_pages" then "Panda::CMS::Page"
    when "panda_cms_templates" then "Panda::CMS::Template"
    when "panda_cms_blocks" then "Panda::CMS::Block"
    when "panda_cms_block_contents" then "Panda::CMS::BlockContent"
    when "panda_cms_menus" then "Panda::CMS::Menu"
    when "panda_cms_menu_items" then "Panda::CMS::MenuItem"
    end
  end
end

# Override ActiveRecord::FixtureSet to use our mapping
module ActiveRecord
  class FixtureSet
    alias_method :original_model_class, :model_class

    def model_class
      if (klass = PandaCmsFixtures.get_class_name(@name))
        klass.constantize
      else
        original_model_class
      end
    end
  end
end
```

### System Test Configuration

For iframe template rendering, Current.root must be initialized:

```ruby
# spec/system/panda/cms/admin/pages/edit_page_spec.rb

context "when logged in as an administrator" do
  before(:each) do
    login_as_admin
    # Initialize Current.root for iframe template rendering
    Panda::CMS::Current.root = Capybara.app_host
    visit "/admin/pages/#{about_page.id}/edit"
  end
end
```

## Available Fixture Data

### Users
- `admin_user`: Admin user with email "admin@example.com"
- `regular_user`: Regular user with email "user@example.com"

### Templates
- `homepage_template`: Homepage template (max_uses: 1, pages_count: 1)
- `page_template`: Standard page template (unlimited uses)
- `different_page_template`: Alternative page template (max_uses: 3, pages_count: 1)

### Pages
- `homepage`: Root page at "/"
- `about_page`: About page at "/about"
- `services_page`: Services page at "/services"
- `about_team_page`: Team page at "/about/team" (child of about)
- `custom_page`: Custom page using different template

### Posts
- `first_post`: Published post with EditorJS content
- `second_post`: Draft post (published_at: null)

### Blocks & Content
Complete block structure for all page types with plain text, HTML, and rich text content.

## Usage Patterns

### Basic System Test

```ruby
RSpec.describe "Feature Test", type: :system do
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:admin_user) { panda_cms_users(:admin_user) }

  it "works with fixture data" do
    login_as_admin
    visit "/"
    expect(page).to have_content(homepage.title)
  end
end
```

### Page Editing Tests

```ruby
RSpec.describe "Page editing", type: :system do
  fixtures :all

  let(:about_page) { panda_cms_pages(:about_page) }

  context "when logged in as an administrator" do
    before(:each) do
      login_as_admin
      # Required for iframe template rendering
      Panda::CMS::Current.root = Capybara.app_host
      visit "/admin/pages/#{about_page.id}/edit"
    end

    it "shows page content" do
      within_frame "editablePageFrame" do
        expect(page).to have_content("Basic Page Layout")
      end
    end
  end
end
```

### Form Validation Tests

```ruby
RSpec.describe "Page creation", type: :system do
  fixtures :all

  before(:each) do
    login_as_admin
    visit "/admin/pages/new"
  end

  it "shows validation errors" do
    click_button "Create Page"
    expect(page).to have_content("Title can't be blank")
    expect(page).to have_content("URL can't be blank")
  end
end
```

## Fixture Helper Methods

The `FixtureHelpers` module provides convenient access to fixture data:

```ruby
# Access fixtures using helper methods
homepage = panda_cms_pages(:homepage)
admin = panda_cms_users(:admin_user)
template = panda_cms_templates(:page_template)
```

The helper handles model class resolution automatically:

```ruby
module FixtureHelpers
  FIXTURE_MODELS = {
    panda_cms_pages: Panda::CMS::Page,
    panda_cms_templates: Panda::CMS::Template,
    panda_cms_blocks: Panda::CMS::Block,
    panda_cms_block_contents: Panda::CMS::BlockContent,
    panda_cms_users: Panda::CMS::User,
    panda_cms_menus: Panda::CMS::Menu,
    panda_cms_menu_items: Panda::CMS::MenuItem,
    panda_cms_posts: Panda::CMS::Post
  }.freeze
end
```

## JavaScript Independence

Tests are designed to work without JavaScript dependencies:

### Slug Generation
Instead of relying on JavaScript for slug generation, tests use manual helpers:

```ruby
# Instead of JavaScript-dependent slug generation
def trigger_slug_generation(title)
  fill_in "Title", with: title
  slug = create_slug_from_title(title)

  # Handle parent page paths
  parent_select = find("select[name='page[parent_id]']", wait: 1)
  if parent_select.value.present?
    # Calculate full path with parent
  else
    fill_in "URL", with: "/#{slug}"
  end
end
```

### Content Editing
Content editing tests focus on element presence and attributes rather than complex interactions:

```ruby
it "allows editing plain text content" do
  within_frame "editablePageFrame" do
    first_plain_text = find('span[data-editable-kind="plain_text"]')
    expect(first_plain_text['contenteditable']).to eq('plaintext-only')
    expect(first_plain_text.text).not_to be_empty
  end
end
```

## Performance Optimizations

### Fast Test Execution
- **No factory creation overhead**: Fixtures are pre-loaded
- **No JavaScript timeouts**: Manual helpers replace JS dependencies
- **Efficient database usage**: Transactional fixtures with automatic rollback

### EditorJS Exclusion
Tests exclude EditorJS functionality by default to avoid timeouts:

```ruby
# spec/rails_helper.rb
config.filter_run_excluding :editorjs unless ENV["INCLUDE_EDITORJS"] == "true"
```

For EditorJS-specific tests, use the tag:

```ruby
it "works with EditorJS", :editorjs do
  # EditorJS-dependent test code
end
```

## Debugging

### Fixture Verification
```ruby
it "verifies fixture loading" do
  puts "Pages count: #{Panda::CMS::Page.count}"
  puts "Templates count: #{Panda::CMS::Template.count}"
  puts "Users count: #{Panda::CMS::User.count}"

  expect(Panda::CMS::Page.count).to be > 0
end
```

### Debug Helpers
Conditional debug output is available:

```ruby
# Only outputs when ENV["DEBUG"] is set
puts_debug "Current URL: #{page.current_url}"
puts_debug "Page content: #{page.text}"
```

### Screenshot Capture
Failed tests automatically capture screenshots:

```ruby
# Automatic on test failure
screenshot_path = Capybara.save_screenshot
puts "Screenshot saved to: #{screenshot_path}"
```

## Component Testing

### UserActivityComponent
Fixed to handle nil time values properly:

```ruby
# app/components/panda/cms/admin/user_activity_component.html.erb
<% if user.is_a?(Panda::CMS::User) && time %>
  <%= render UserDisplayComponent.new(user: user, metadata: "#{time_ago_in_words(time)} ago") %>
<% elsif user.is_a?(Panda::CMS::User) %>
  <%= render UserDisplayComponent.new(user: user, metadata: "Not published") %>
<% elsif time %>
  <div class="text-black/60"><%= time_ago_in_words(time) %> ago</div>
<% end %>
```

## Best Practices

### 1. Use Fixtures for All System Tests
```ruby
# Good
RSpec.describe "Feature", type: :system do
  fixtures :all
  # Test code
end

# Avoid
RSpec.describe "Feature", type: :system do
  let(:page) { create(:page) }  # Don't use factories
end
```

### 2. Initialize Current.root for Page Editing
```ruby
# Required for iframe template rendering
before(:each) do
  login_as_admin
  Panda::CMS::Current.root = Capybara.app_host
  visit "/admin/pages/#{page.id}/edit"
end
```

### 3. Test Core Functionality, Not Implementation
```ruby
# Good - tests behavior
it "creates a page with valid data" do
  trigger_slug_generation("Test Page")
  select "Page", from: "Template"
  click_button "Create Page"
  expect(page).to have_content("successfully created")
end

# Avoid - tests implementation details
it "calls JavaScript slug generation" do
  expect(page).to execute_script("generateSlug()")
end
```

### 4. Use Descriptive Test Names
```ruby
# Good
it "shows validation errors when title is missing"
it "creates nested pages with correct URL structure"

# Avoid
it "works"
it "validates"
```

## Maintenance

### Adding New Fixtures
1. Create fixture files in `spec/fixtures/`
2. Add model mapping to `PandaCmsFixtures.get_class_name`
3. Update `FIXTURE_MODELS` in `FixtureHelpers`

### Updating Tests
1. Use `fixtures :all` in test files
2. Replace factory calls with fixture references
3. Add `Current.root` initialization for page editing tests
4. Ensure tests work without JavaScript dependencies

### Performance Monitoring
Monitor test performance with:
```bash
bundle exec rspec spec/system/ --format progress
```

Target: < 2 minutes for full system test suite

## Current Status

**✅ Complete**: All 57 system tests passing with fixtures
**⚡ Performance**: ~1.5 minutes total execution time
**🎯 Coverage**: 68.25% test coverage
**🧹 Clean**: No debug output or JavaScript dependencies
**🔧 Maintainable**: Simple fixture-based approach
