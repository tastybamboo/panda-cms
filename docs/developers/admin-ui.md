---
title: Admin UI Development
parent: Developer Documentation
layout: default
nav_order: 5
---

# Admin UI Development

This guide covers developing admin UI pages for Panda CMS and extensions.

## Breadcrumbs

The admin layout automatically renders breadcrumbs for navigation. Use the `add_breadcrumb` helper method in your controller to configure breadcrumbs.

### Basic Usage

```ruby
class MyController < Panda::CMS::Admin::BaseController
  before_action :set_breadcrumbs

  private

  def set_breadcrumbs
    add_breadcrumb "Section Name", section_path
    add_breadcrumb "Page Name", page_path
  end
end
```

### Example: My Profile Section

```ruby
module Panda
  module CMS
    module Admin
      module MyProfile
        class ApiTokensController < Panda::CMS::Admin::BaseController
          before_action :set_breadcrumbs

          def index
            # Your action code
          end

          private

          def set_breadcrumbs
            add_breadcrumb "My Profile", "#"
            add_breadcrumb "API Tokens", manage_my_profile_api_tokens_path
          end
        end
      end
    end
  end
end
```

### How It Works

- The admin layout (`panda/core/admin.html.erb`) automatically renders breadcrumbs
- Breadcrumbs always start with a Home icon linking to the admin dashboard
- Each breadcrumb item has a name and optional path
- The last breadcrumb represents the current page

### Important Notes

**Do not** manually render `Panda::Core::Admin::BreadcrumbComponent` in your views. The layout handles breadcrumb rendering automatically. Using the component directly will cause duplicate breadcrumbs.

❌ **Incorrect:**

```erb
<%# Don't do this! %>
<%= render Panda::Core::Admin::BreadcrumbComponent.new(
  items: [
    { text: "My Profile", href: "#" },
    { text: "API Tokens", href: manage_my_profile_api_tokens_path }
  ]
) %>
```

✅ **Correct:**

```ruby
# In your controller
before_action :set_breadcrumbs

def set_breadcrumbs
  add_breadcrumb "My Profile", "#"
  add_breadcrumb "API Tokens", manage_my_profile_api_tokens_path
end
```

## Admin Components

Panda CMS provides several ViewComponent components for building consistent admin interfaces:

### ContainerComponent

Wraps your page content with consistent spacing and layout.

```erb
<%= render Panda::Core::Admin::ContainerComponent.new do |component| %>
  <% component.heading(text: "Page Title", level: 1, icon: "fa-solid fa-icon") %>

  <%# Your content here %>
<% end %>
```

### PanelComponent

Groups related content in a panel with optional heading.

```erb
<%= render Panda::Core::Admin::PanelComponent.new do |panel| %>
  <% panel.heading(text: "Panel Title", level: :panel, icon: "fa-solid fa-icon") %>
  <% panel.body do %>
    <%# Panel content %>
  <% end %>
<% end %>
```

### TableComponent

Renders data tables with consistent styling.

```erb
<%= render Panda::Core::Admin::TableComponent.new(term: "item", rows: @items, icon: "fa-solid fa-icon") do |table| %>
  <% table.column("Name") { |item| item.name } %>
  <% table.column("Status") { |item| render Panda::Core::Admin::TagComponent.new(status: item.status) } %>
<% end %>
```

### TagComponent

Displays status tags with color coding.

```erb
<%= render Panda::Core::Admin::TagComponent.new(
  text: "Active",
  status: :active  # or :neutral, :warning, :danger
) %>
```

## Further Reading

- [ViewComponent Documentation](https://viewcomponent.org/)
- [ViewComponent Guide](https://viewcomponent.org/guide/)
