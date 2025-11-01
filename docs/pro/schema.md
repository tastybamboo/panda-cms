# Panda CMS Pro Database Schema

This document describes the database schema for Panda CMS Pro features.

## Overview

Panda CMS Pro adds collaborative content management features including versioning, suggestions, comments, role-based permissions, and content source tracking. All Pro tables use the `panda_cms_pro_` prefix.

## Tables

### `panda_cms_pro_roles`

Role-based permission system for content management.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `name` | string | Role name (unique) |
| `description` | string | Human-readable description |
| `permissions` | jsonb | Permission flags (default: {}) |
| `custom_metadata` | jsonb | Additional metadata (default: {}) |
| `system_role` | boolean | Whether this is a system-defined role (default: false) |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `name` (unique)

**Default Roles:**
- `admin` - Full access to all features
- `editor` - Create, edit, and publish content
- `content_creator` - Create and edit, requires approval to publish
- `reviewer` - Review and approve suggestions
- `contributor` - Make suggestions and comments
- `viewer` - Read-only access

### `panda_cms_pro_user_roles`

Join table linking users to roles with optional one-time access tokens.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key to `panda_core_users` |
| `panda_cms_pro_role_id` | uuid | Foreign key to `panda_cms_pro_roles` |
| `access_token` | string | One-time access token for temporary contributors |
| `token_expires_at` | datetime | Expiration for access token |
| `granted_by_id` | uuid | User who granted this role |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `user_id`
- `panda_cms_pro_role_id`
- `access_token` (unique)

**Foreign Keys:**
- `user_id` → `panda_core_users.id`
- `panda_cms_pro_role_id` → `panda_cms_pro_roles.id`

### `panda_cms_pro_content_versions`

Version history for all versionable content (polymorphic).

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `versionable_type` | string | Polymorphic type (Page, Post, etc.) |
| `versionable_id` | uuid | Polymorphic ID |
| `user_id` | uuid | User who created this version |
| `version_number` | integer | Sequential version number |
| `content` | jsonb | Snapshot of content at this version |
| `change_summary` | text | Description of changes |
| `source` | string | How version was created (manual, ai_generated, suggestion_approved) |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `versionable_type`, `versionable_id`
- `user_id`
- `version_number`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`

**Scopes:**
- `ordered` - Orders by version_number descending

### `panda_cms_pro_content_changes`

Granular tracking of individual changes within versions.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `panda_cms_pro_content_version_id` | uuid | Foreign key to content_versions |
| `change_type` | enum | Type of change (addition, deletion, modification, callout, citation) |
| `field_name` | string | Which field changed |
| `old_value` | jsonb | Previous value |
| `new_value` | jsonb | New value |
| `metadata` | jsonb | Additional context |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `panda_cms_pro_content_version_id`
- `change_type`

**Foreign Keys:**
- `panda_cms_pro_content_version_id` → `panda_cms_pro_content_versions.id`

**Enums:**
- `panda_cms_pro_content_change_type`: `addition`, `deletion`, `modification`, `callout`, `citation`

### `panda_cms_pro_content_suggestions`

Contributor suggestions with approval workflow (polymorphic).

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `suggestable_type` | string | Polymorphic type |
| `suggestable_id` | uuid | Polymorphic ID |
| `user_id` | uuid | User who made the suggestion |
| `suggestion_type` | enum | Type of suggestion (edit, addition, deletion, comment, citation) |
| `status` | enum | Workflow status (pending, specialist_review, admin_review, approved, rejected) |
| `content` | jsonb | Suggested content or changes |
| `reason` | text | Explanation for suggestion |
| `review_notes` | text | Reviewer feedback |
| `reviewed_by_id` | uuid | User who reviewed |
| `reviewed_at` | datetime | When reviewed |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `suggestable_type`, `suggestable_id`
- `user_id`
- `status`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`
- `reviewed_by_id` → `panda_core_users.id`

**Enums:**
- `panda_cms_pro_suggestion_status`: `pending`, `specialist_review`, `admin_review`, `approved`, `rejected`
- `panda_cms_pro_suggestion_type`: `edit`, `addition`, `deletion`, `comment`, `citation`

**Scopes:**
- `for_review` - Suggestions pending review
- `approved` - Approved suggestions
- `rejected` - Rejected suggestions

### `panda_cms_pro_content_comments`

Threaded discussion system for content (polymorphic).

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `commentable_type` | string | Polymorphic type |
| `commentable_id` | uuid | Polymorphic ID |
| `user_id` | uuid | Comment author |
| `parent_id` | uuid | Parent comment for threading |
| `content` | text | Comment content |
| `resolved` | boolean | Whether comment is resolved (default: false) |
| `resolved_by_id` | uuid | User who resolved |
| `resolved_at` | datetime | When resolved |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `commentable_type`, `commentable_id`
- `user_id`
- `parent_id`
- `resolved`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`
- `resolved_by_id` → `panda_core_users.id`
- `parent_id` → `panda_cms_pro_content_comments.id`

**Scopes:**
- `unresolved` - Comments not yet resolved
- `root` - Top-level comments (no parent)

### `panda_cms_pro_content_sources`

Domain-based trust management for content sources.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `domain` | string | Domain name (e.g., "ncbi.nlm.nih.gov") |
| `trust_level` | enum | Trust level (always_prefer, trusted, neutral, untrusted, never_use) |
| `default_callout_type` | string | Default callout type for this source |
| `notes` | text | Notes about this source |
| `metadata` | jsonb | Additional metadata |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `domain` (unique)
- `trust_level`

**Enums:**
- `panda_cms_pro_source_trust_level`: `always_prefer`, `trusted`, `neutral`, `untrusted`, `never_use`

**Scopes:**
- `preferred` - always_prefer sources
- `trusted_sources` - always_prefer and trusted
- `untrusted_sources` - untrusted and never_use
- `ordered` - by trust_level desc, domain asc

### `panda_cms_pro_content_sync_logs`

Staging to production synchronization tracking.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `user_id` | uuid | User who initiated sync |
| `sync_type` | enum | push or pull |
| `status` | enum | Sync status (pending, in_progress, completed, failed, rolled_back) |
| `started_at` | datetime | When sync started |
| `completed_at` | datetime | When sync completed |
| `items_synced` | jsonb | Array of synced items |
| `summary` | jsonb | Summary statistics |
| `error_log` | text | Error messages if failed |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

**Indexes:**
- `user_id`
- `status`
- `created_at`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`

**Enums:**
- `panda_cms_pro_sync_type`: `push`, `pull`
- `panda_cms_pro_sync_status`: `pending`, `in_progress`, `completed`, `failed`, `rolled_back`

**Scopes:**
- `recent` - Ordered by created_at desc
- `successful` - Completed syncs
- `failed_syncs` - Failed syncs
- `pushes` - Push operations
- `pulls` - Pull operations

## Additional Columns

### Pages (`panda_cms_pages`)

Pro features add:
- `contributor_count` (integer, default: 0)
- `last_contributed_at` (datetime)
- `workflow_status` (string, default: "draft")

### Posts (`panda_cms_posts`)

Pro features add:
- `contributor_count` (integer, default: 0)
- `last_contributed_at` (datetime)
- `workflow_status` (string, default: "draft")

## Concerns

### `Panda::CMS::Pro::Versionable`

Included in Page and Post models to provide:
- `content_versions` association
- `content_suggestions` association
- `content_comments` association
- `create_version!` method
- `restore_version!` method
- `latest_version` method
- `contributors` method
- Auto-versioning on content changes (if enabled)

## Seed Data

Default roles and content sources are provided in:
- `db/seeds/pro_roles.rb` - 6 system roles
- `db/seeds/pro_content_sources.rb` - 32 trusted sources

Load with:
```ruby
load Rails.root.join("db/seeds/pro_roles.rb")
load Rails.root.join("db/seeds/pro_content_sources.rb")
```

## Migration Files

Pro migrations are located in `db/migrate/` with timestamps `20251101120000-120009`:
1. `create_panda_cms_pro_roles`
2. `create_panda_cms_pro_user_roles`
3. `create_panda_cms_pro_content_versions`
4. `create_panda_cms_pro_content_changes`
5. `create_panda_cms_pro_content_suggestions`
6. `create_panda_cms_pro_content_comments`
7. `create_panda_cms_pro_content_sources`
8. `create_panda_cms_pro_content_sync_logs`
9. `add_pro_contributor_tracking_to_pages`
10. `add_pro_contributor_tracking_to_posts`
