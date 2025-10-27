# Collections (Pro)

> Requires the `panda-cms-pro` gem. Core will raise `Panda::CMS::Features::MissingFeatureError` if the gem is missing.

## Overview

Collections let editors manage repeatable content (trustees, partners, FAQs, testimonials). Each collection defines a schema composed of fields (text, long text, URL, image). Editors then create *items* that fill in those fields.

## Admin Workflow

1. Install and bundle `panda-cms-pro` in the host app.
2. Run `bin/rails db:migrate` so the new tables are created.
3. In the admin sidebar, open **Collections → Add Collection**.
4. Define fields (e.g., `Name`, `Photo`, `Biography`). Save.
5. Use **Manage Items** to add entries.

## Template Usage

Helpers live in `Panda::CMS::ApplicationHelper` once the pro gem is loaded:

```erb
<% panda_cms_collection_items("trustees").each do |trustee| %>
  <article>
    <h3><%= trustee.value_for("name") %></h3>
    <% if (photo = panda_cms_collection_asset(trustee, :photo)) %>
      <%= image_tag photo.variant(resize_to_fill: [320, 320]) %>
    <% end %>
    <p><%= trustee.value_for("biography") %></p>
  </article>
<% end %>
```

- `panda_cms_collection(slug)` returns the full `Collection` record.
- `panda_cms_collection_items(slug, include_unpublished: false)` returns a scope filtered to visible items.
- `panda_cms_collection_asset(item, key)` fetches the Active Storage attachment for an image field.

## Permissions & Feature Gating

- The sidebar link only appears if `Panda::CMS::Features.enabled?(:collections)`.
- View helpers call `Panda::CMS::Features.require!(:collections)` so open-source installs receive a friendly error instead of `NameError`.

## Data Model

Tables introduced by `panda-cms-pro`:

- `panda_cms_collections` – schema definitions + metadata.
- `panda_cms_collection_fields` – per-field configuration (type, required, instructions).
- `panda_cms_collection_items` – reusable entries (JSON data + attachments).

Attachments rely on Active Storage and are tagged with metadata so each field keeps its own image.
