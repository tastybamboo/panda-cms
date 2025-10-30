# Phlex Component Quick Start Guide

Get started building components with the shared `Panda::Core::Base` in under 5 minutes.

## Prerequisites

✅ You've run `bundle install` in panda-core and panda-cms
✅ You understand basic Tailwind CSS
✅ You're familiar with the Panda CMS admin interface

## Your First Component (2 minutes)

### 1. Create the Component

```ruby
# app/components/panda/cms/admin/my_first_component.rb
module Panda
  module CMS
    module Admin
      class MyFirstComponent < Panda::Core::Base
        prop :title, String
        prop :variant, Symbol, default: :default

        def view_template
          div(**@attrs) do
            h2(class: "text-xl font-bold") { @title }
            p { "This is my first Phlex component!" }
          end
        end

        def default_attrs
          {
            class: "p-6 rounded-lg #{variant_classes}"
          }
        end

        private

        def variant_classes
          case @variant
          when :primary then "bg-blue-100 border-blue-300"
          when :success then "bg-green-100 border-green-300"
          else "bg-gray-100 border-gray-300"
          end
        end
      end
    end
  end
end
```

### 2. Use in a View

```erb
<%# app/views/panda/cms/admin/pages/index.html.erb %>
<%= render Panda::CMS::Admin::MyFirstComponent.new(
  title: "Welcome to Panda CMS",
  variant: :primary
) %>
```

## Essential Patterns

### Type-Safe Props

```ruby
class ButtonComponent < Panda::Core::Base
  # Required prop
  prop :text, String

  # Optional with default
  prop :size, Symbol, default: :medium

  # Boolean (use _Boolean, not Boolean)
  prop :disabled, _Boolean, default: false

  # Nullable
  prop :icon, _Nilable(String)

  # Union type
  prop :variant, _Union(:primary, :secondary, :danger)
end
```

`★ Insight ─────────────────────────────────────`
**Why Use Literal Props?**
- **Type Safety**: Catches errors at component initialization, not in production
- **IDE Support**: Better autocomplete and inline documentation
- **Self-Documenting**: Props clearly show what the component needs
- **Runtime Validation**: Invalid props raise helpful errors immediately
`─────────────────────────────────────────────────`

### Attribute Merging

```ruby
class CardComponent < Panda::Core::Base
  def view_template
    # @attrs contains merged user + default attributes
    div(**@attrs) do
      yield
    end
  end

  def default_attrs
    {
      class: "rounded-lg p-6",
      data: { controller: "card" }
    }
  end
end

# Usage - attributes merge automatically
render CardComponent.new(class: "mt-4", data: { action: "click->card#open" })
# Result: class="rounded-lg p-6 mt-4" data-controller="card" data-action="click->card#open"
```

### Avoiding Property Name Conflicts with Phlex

**Important**: Phlex defines methods for all HTML elements (like `text`, `link`, `form`, `select`) and common terms (like `href`, `style`, `size`). Always use `@instance_variables` instead of direct property accessors to avoid conflicts:

```ruby
class AlertComponent < Panda::Core::Base
  prop :text, String
  prop :level, Symbol, default: :info

  def view_template
    # ❌ WRONG - 'text' and 'level' conflict with Phlex methods
    # div { text }

    # ✅ CORRECT - Use @instance_variables
    div(**@attrs) { @text }
  end

  def default_attrs
    { class: "alert alert-#{@level}" }  # ✅ Use @level
  end
end
```

### Tailwind Class Merging

```ruby
class AlertComponent < Panda::Core::Base
  prop :padding, Symbol, default: :medium

  def default_attrs
    { class: "rounded-lg #{padding_classes}" }
  end

  def padding_classes
    case @padding
    when :small then "p-2"
    when :large then "p-8"
    else "p-4"
    end
  end
end

# Tailwind conflicts resolved automatically via TailwindMerge
render AlertComponent.new(class: "p-6")  # User p-6 wins over default p-4
```

`★ Insight ─────────────────────────────────────`
**How TailwindMerge Works:**
The `Panda::Core::Base` component uses TailwindMerge to intelligently merge conflicting Tailwind classes. When you provide `class: "p-6"` and the component has `class: "p-4 bg-white"`, the result is `"p-6 bg-white"` - the conflicting padding is resolved, but other classes are preserved.
`─────────────────────────────────────────────────`

### Block Content

```ruby
class PanelComponent < Panda::Core::Base
  def view_template(&block)
    div(**@attrs, &block)
  end

  def default_attrs
    { class: "panel bg-white rounded-lg shadow" }
  end
end

# Usage with block
render PanelComponent.new do
  h3 { "Panel Title" }
  p { "Panel content goes here" }
end
```

### Slots Pattern for Complex Components

```ruby
class ContainerComponent < Panda::Core::Base
  def view_template(&block)
    # Yield self to allow slot definition
    yield(self) if block_given?

    main(**@attrs) do
      div(class: "container mx-auto") do
        @heading_content&.call
        @tab_bar_content&.call

        section(class: "content") do
          @main_content&.call if @main_content
        end
      end
    end
  end

  # Slot methods capture blocks for later rendering
  def content(&block)
    @main_content = block
  end

  def heading(**props, &block)
    @heading_content = -> { render(HeadingComponent.new(**props), &block) }
  end

  def tab_bar(**props)
    @tab_bar_content = -> { render(TabBarComponent.new(**props)) }
  end
end

# Usage
render ContainerComponent.new do |container|
  container.heading(text: "Pages")
  container.tab_bar(tabs: [...])
  container.content do
    p { "Main content here" }
  end
end
```

## Real-World CMS Examples

### Admin Heading with Action Button

```ruby
module Panda
  module CMS
    module Admin
      class HeadingComponent < Panda::Core::Base
        prop :text, String
        prop :level, Integer, default: 2

        def view_template(&block)
          # Allow button slot to be defined
          yield(self) if block_given?

          heading_tag do
            div(class: "grow") { @text }
            @button_content&.call if @button_content
          end
        end

        def button(**props)
          @button_content = -> { render(ButtonComponent.new(**props)) }
        end

        private

        def heading_tag(&block)
          case @level
          when 1 then h1(**@attrs, &block)
          when 2 then h2(**@attrs, &block)
          when 3 then h3(**@attrs, &block)
          else h2(**@attrs, &block)
          end
        end

        def default_attrs
          { class: "flex items-center justify-between mb-4" }
        end
      end
    end
  end
end

# Usage in a view
<%= render Panda::CMS::Admin::HeadingComponent.new(text: "Pages") do |heading|
  heading.button(text: "New Page", href: new_admin_page_path, action: :add)
end %>
```

### Data Table Component

```ruby
module Panda
  module CMS
    module Admin
      class TableComponent < Panda::Core::Base
        prop :rows, Array
        prop :term, String, default: "item"

        def view_template(&block)
          # Capture column definitions
          instance_eval(&block) if block_given?

          if @rows.any?
            render_table_with_rows
          else
            render_empty_table
          end
        end

        def column(header, &block)
          @columns ||= []
          @columns << { header: header, block: block }
        end

        private

        def render_table_with_rows
          table(**@attrs) do
            thead do
              tr do
                @columns.each do |col|
                  th { col[:header] }
                end
              end
            end
            tbody do
              @rows.each do |row|
                tr do
                  @columns.each do |col|
                    td { col[:block].call(row) }
                  end
                end
              end
            end
          end
        end

        def render_empty_table
          div(class: "empty-state") do
            p { "No #{@term.pluralize} found" }
          end
        end
      end
    end
  end
end

# Usage
<%= render Panda::CMS::Admin::TableComponent.new(rows: @pages, term: "page") do |table|
  table.column("Title") { |page| page.title }
  table.column("Status") { |page| page.status }
  table.column("Updated") { |page| time_ago_in_words(page.updated_at) }
end %>
```

### Status Badge Component

```ruby
module Panda
  module CMS
    module Admin
      class TagComponent < Panda::Core::Base
        prop :status, Symbol
        prop :text, _Nilable(String)

        def view_template
          span(**@attrs) { display_text }
        end

        def default_attrs
          { class: "badge #{status_classes}" }
        end

        private

        def display_text
          @text || @status.to_s.titleize
        end

        def status_classes
          case @status
          when :active then "bg-green-100 text-green-800"
          when :draft then "bg-yellow-100 text-yellow-800"
          when :archived then "bg-gray-100 text-gray-800"
          else "bg-blue-100 text-blue-800"
          end
        end
      end
    end
  end
end
```

## Testing Components

### RSpec Unit Test

```ruby
# spec/components/panda/cms/admin/tag_component_spec.rb
require "rails_helper"

RSpec.describe Panda::CMS::Admin::TagComponent, type: :component do
  it "renders with status" do
    component = described_class.new(status: :active)
    output = Capybara.string(component.call)

    expect(output).to have_css(".badge")
    expect(output).to have_text("Active")
  end

  it "applies correct styling for draft status" do
    component = described_class.new(status: :draft)
    output = Capybara.string(component.call)

    expect(output).to have_css(".bg-yellow-100")
  end

  it "validates prop types" do
    expect {
      described_class.new(status: 123)  # Wrong type
    }.to raise_error(Literal::TypeError)
  end
end
```

`★ Insight ─────────────────────────────────────`
**Testing Pattern for Phlex Components:**
1. Create component instance with props
2. Call `component.call` to get HTML string
3. Wrap in `Capybara.string()` for CSS selector matching
4. Use Capybara matchers (`have_css`, `have_text`, etc.)
This pattern works without Rails view context, making tests fast and isolated.
`─────────────────────────────────────────────────`

## Common Pitfalls

### ❌ Don't: Access Props Directly When They Conflict

```ruby
# BAD - 'text' conflicts with Phlex's text() method
class AlertComponent < Panda::Core::Base
  prop :text, String

  def view_template
    div { text }  # ❌ This calls Phlex's text() method, not your prop!
  end
end
```

### ✅ Do: Use @instance_variables

```ruby
# GOOD
class AlertComponent < Panda::Core::Base
  prop :text, String

  def view_template
    div { @text }  # ✅ Accesses the instance variable directly
  end
end
```

### ❌ Don't: Use Boolean (Use _Boolean)

```ruby
# BAD - Ruby's Boolean doesn't exist
prop :disabled, Boolean  # ❌ NameError

# GOOD
prop :disabled, _Boolean  # ✅
```

### ❌ Don't: Forget to Merge @attrs

```ruby
# BAD - ignores user attributes
def view_template
  div(class: "my-class") { "Content" }
end

# GOOD - merges with user attributes
def view_template
  div(**@attrs) { "Content" }
end
```

### ❌ Don't: Mutate Props

```ruby
# BAD
class ListComponent < Panda::Core::Base
  prop :items, Array

  def view_template
    @items << "new item"  # ❌ Mutates prop!
    ul { @items.each { |item| li { item } } }
  end
end

# GOOD
class ListComponent < Panda::Core::Base
  prop :items, Array

  def view_template
    all_items = @items + ["new item"]  # ✅ Creates new array
    ul { all_items.each { |item| li { item } } }
  end
end
```

## Rails Helper Integration

### Using Rails Helpers in Components

```ruby
class UserActivityComponent < Panda::Core::Base
  # Include Rails helpers as needed
  include ActionView::Helpers::DateHelper

  prop :user, Object
  prop :at, _Nilable(Object)

  def view_template
    return unless @user

    render Panda::Core::Admin::UserDisplayComponent.new(
      user: @user,
      metadata: @at ? "#{time_ago_in_words(@at)} ago" : "Not published"
    )
  end
end
```

`★ Insight ─────────────────────────────────────`
**Phlex and Rails Helpers:**
The deprecated `helpers` method in Phlex has been replaced with explicit module inclusion. Include only the helper modules you need (like `ActionView::Helpers::DateHelper`) rather than accessing all helpers through the deprecated `helpers` proxy.
`─────────────────────────────────────────────────`

## Component Organization

```
app/components/
└── panda/
    └── cms/
        └── admin/
            ├── button_component.rb
            ├── container_component.rb
            ├── heading_component.rb
            ├── panel_component.rb
            ├── statistics_component.rb
            ├── tab_bar_component.rb
            ├── table_component.rb
            ├── tag_component.rb
            ├── user_activity_component.rb
            └── user_display_component.rb
```

## Cheat Sheet

```ruby
# Component Structure
class MyComponent < Panda::Core::Base
  # 1. Props (use @ to access)
  prop :required_prop, String
  prop :optional_prop, Symbol, default: :default

  # 2. Render method
  def view_template(&block)
    element(**@attrs, &block)
  end

  # 3. Default attributes
  def default_attrs
    { class: "my-classes" }
  end

  # 4. Private helpers
  private

  def helper_method
    # Always use @prop_name to access props
  end
end

# Common Prop Types
prop :string, String
prop :symbol, Symbol
prop :int, Integer
prop :float, Float
prop :bool, _Boolean
prop :array, Array
prop :hash, Hash
prop :nullable, _Nilable(String)
prop :union, _Union(:a, :b, :c)

# HTML Elements
div, span, p, h1..h6, ul, ol, li, table, tr, td, th,
button, a, img, input, select, textarea, form, label

# Special Methods
plain "text"        # Output text without escaping
whitespace          # Add whitespace
comment { "..." }   # HTML comment
render OtherComponent.new(...)  # Render child component

# Tailwind Merging (automatic via TailwindMerge)
# User class: "px-6"
# Default class: "px-4 py-2"
# Result: "px-6 py-2"  ← conflicts resolved
```

## Next Steps

1. **Study Existing Components** - Look at panda-core admin components
2. **Build Your First Component** - Start with something simple
3. **Write Tests** - Create RSpec tests using Capybara
4. **Share Patterns** - Document reusable patterns for your team
5. **Read Docs** - [Phlex.fun](https://www.phlex.fun) for deep dive

## Getting Help

- **Base Component** - `panda-core/app/components/panda/core/base.rb`
- **Example Components** - `panda-core/app/components/panda/core/admin/`
- **Component Tests** - `panda-core/spec/components/panda/core/admin/`
- **Phlex Docs** - https://www.phlex.fun
- **Literal Docs** - https://github.com/joeldrapper/literal

Happy component building! 🎨
