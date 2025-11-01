# Content Workflow Database Schema

This document describes the database schema for Panda CMS Pro's content workflow features, including collaborative editing, version control, suggestions, and staging-to-production sync.

## Overview

The content workflow system consists of several interconnected components:

1. **Roles & Permissions** - Multi-level access control
2. **Version Control** - Complete history of content changes
3. **Suggestions & Approval** - Collaborative editing workflow
4. **Comments** - Discussion system for content
5. **Trusted Sources** - Citation quality management
6. **Sync Logs** - Staging to production deployment tracking

All tables follow Panda CMS conventions:
- UUID primary keys using `gen_random_uuid()`
- `panda_cms_` table prefix
- PostgreSQL enums for status/type fields
- Timestamps (`created_at`, `updated_at`)
- Foreign keys to `panda_core_users` for user references

---

## Tables

### panda_cms_roles

Generic role system for content contributors.

**Columns:**
- `id` (uuid, PK) - Unique identifier
- `name` (string, not null, unique) - Role name (e.g., "admin", "editor", "reviewer")
- `description` (string) - Human-readable description
- `permissions` (jsonb, not null, default: {}) - Permission flags
- `custom_metadata` (jsonb, default: {}) - App-specific metadata (e.g., specialty)
- `system_role` (boolean, not null, default: false) - Whether role is system-defined
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `name` (unique)

**Default Roles:**
- `admin` - Full control, all permissions
- `editor` - Approve/publish content, manage workflow
- `content_creator` - Create and edit draft content
- `reviewer` - Review content, suggest changes (elevated trust)
- `contributor` - Suggest edits and comments
- `viewer` - Read-only access to drafts

**Permissions Structure:**
```json
{
  "create_content": true,
  "edit_content": true,
  "publish_content": false,
  "approve_suggestions": false,
  "manage_users": false,
  "sync_content": false
}
```

**Custom Metadata Example:**
```json
{
  "specialty": "medical",
  "requires_verification": true,
  "approval_priority": "high"
}
```

---

### panda_cms_user_roles

Join table linking users to roles with optional expiry.

**Columns:**
- `id` (uuid, PK)
- `user_id` (uuid, not null, FK → panda_core_users) - User reference
- `panda_cms_role_id` (uuid, not null, FK → panda_cms_roles) - Role reference
- `expires_at` (datetime) - When role access expires (for temporary access)
- `access_token` (string, unique) - Secure token for one-time access
- `access_token_expires_at` (datetime) - Token expiration
- `metadata` (jsonb, default: {}) - Additional context
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `user_id`
- `panda_cms_role_id`
- `access_token` (unique)
- `[user_id, panda_cms_role_id]` (unique composite)

**Foreign Keys:**
- `user_id` → `panda_core_users.id`
- `panda_cms_role_id` → `panda_cms_roles.id`

**Use Cases:**
- Permanent role assignment: Set `user_id`, `panda_cms_role_id`, leave `expires_at` null
- Temporary access: Set `expires_at` to future date
- One-time contributor: Generate `access_token`, set `access_token_expires_at`

---

### panda_cms_content_versions

Version history for all content (pages, posts, etc.).

**Columns:**
- `id` (uuid, PK)
- `versionable_type` (string, not null) - Model name (e.g., "Panda::CMS::Page")
- `versionable_id` (uuid, not null) - Model ID
- `version_number` (integer, not null, default: 1) - Sequential version number
- `content` (jsonb, not null) - Full content snapshot
- `change_summary` (text) - Human-readable summary of changes
- `user_id` (uuid, FK → panda_core_users) - User who created this version
- `source` (string, default: "manual") - How version was created
  - `manual` - User edited directly
  - `ai_generated` - AI-generated content
  - `suggestion_approved` - Applied from approved suggestion
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `[versionable_type, versionable_id]` (composite)
- `user_id`
- `version_number`
- `created_at`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`

---

### panda_cms_content_changes

Granular tracking of individual changes within versions.

**Columns:**
- `id` (uuid, PK)
- `panda_cms_content_version_id` (uuid, not null, FK → panda_cms_content_versions)
- `section_identifier` (string) - Which section changed (e.g., "introduction", "paragraph-3")
- `change_type` (enum, not null) - Type of change
  - `addition` - New content added
  - `deletion` - Content removed
  - `modification` - Existing content changed
  - `callout` - Callout added/modified
  - `citation` - Citation added/modified
- `old_content` (text) - Content before change
- `new_content` (text) - Content after change
- `metadata` (jsonb, default: {}) - Additional context
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `panda_cms_content_version_id`
- `change_type`

**Foreign Keys:**
- `panda_cms_content_version_id` → `panda_cms_content_versions.id`

**Enum:** `panda_cms_content_change_type`

---

### panda_cms_content_suggestions

Proposed changes from contributors awaiting approval.

**Columns:**
- `id` (uuid, PK)
- `suggestable_type` (string, not null) - Model name
- `suggestable_id` (uuid, not null) - Model ID
- `user_id` (uuid, not null, FK → panda_core_users) - Suggester
- `section_identifier` (string) - Which section to change
- `suggestion_type` (enum, not null) - Type of suggestion
  - `edit` - Modify existing content
  - `addition` - Add new content
  - `deletion` - Remove content
  - `comment` - General feedback
  - `citation` - Add/modify citation
- `status` (enum, not null, default: "pending") - Current status
  - `pending` - Awaiting review
  - `medical_review` - Needs specialist review
  - `admin_review` - Needs admin approval
  - `approved` - Accepted and applied
  - `rejected` - Declined
- `content` (text, not null) - Suggested content/change
- `rationale` (text) - Why this change is suggested
- `metadata` (jsonb, default: {}) - Additional context (sources, etc.)
- `reviewed_by_id` (uuid, FK → panda_core_users) - Who reviewed
- `reviewed_at` (datetime) - When reviewed
- `admin_notes` (text) - Notes from reviewer
- `requires_specialist_review` (boolean, default: false) - Flag for medical/specialist review
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `[suggestable_type, suggestable_id]` (composite)
- `user_id`
- `reviewed_by_id`
- `status`
- `suggestion_type`
- `created_at`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`
- `reviewed_by_id` → `panda_core_users.id`

**Enums:**
- `panda_cms_suggestion_status`
- `panda_cms_suggestion_type`

---

### panda_cms_content_comments

Discussion threads on content sections.

**Columns:**
- `id` (uuid, PK)
- `commentable_type` (string, not null) - Model name
- `commentable_id` (uuid, not null) - Model ID
- `user_id` (uuid, not null, FK → panda_core_users) - Commenter
- `section_identifier` (string) - Which section
- `content` (text, not null) - Comment text
- `parent_id` (uuid, FK → panda_cms_content_comments) - For threaded replies
- `resolved` (boolean, not null, default: false) - Whether issue is resolved
- `resolved_by_id` (uuid, FK → panda_core_users) - Who resolved
- `resolved_at` (datetime) - When resolved
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `[commentable_type, commentable_id]` (composite)
- `user_id`
- `parent_id`
- `resolved`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`
- `resolved_by_id` → `panda_core_users.id`
- `parent_id` → `panda_cms_content_comments.id`

---

### panda_cms_trusted_sources

Domain-based source trust ratings for citations.

**Columns:**
- `id` (uuid, PK)
- `domain` (string, not null, unique) - Domain name (e.g., "nih.gov")
- `trust_level` (enum, not null, default: "neutral") - Trust rating
  - `always_prefer` - Always use when available
  - `trusted` - Reliable source
  - `neutral` - No specific trust level
  - `untrusted` - Use with caution
  - `never_use` - Do not cite
- `default_callout_type` (string) - Suggested callout type (app-specific)
- `notes` (text) - Internal notes about source
- `metadata` (jsonb, default: {}) - Additional context
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `domain` (unique)
- `trust_level`

**Enum:** `panda_cms_source_trust_level`

---

### panda_cms_content_sync_logs

History of staging → production syncs.

**Columns:**
- `id` (uuid, PK)
- `sync_type` (enum, not null) - Direction of sync
  - `push` - Staging → Production
  - `pull` - Production → Staging
- `status` (enum, not null, default: "pending") - Current status
  - `pending` - Queued
  - `in_progress` - Running
  - `completed` - Successful
  - `failed` - Error occurred
  - `rolled_back` - Reverted
- `user_id` (uuid, not null, FK → panda_core_users) - Who initiated
- `items_synced` (jsonb, not null, default: []) - List of synced items
- `summary` (jsonb, default: {}) - Statistics (pages added/modified/deleted)
- `error_log` (text) - Error messages if failed
- `started_at` (datetime) - When sync began
- `completed_at` (datetime) - When sync finished
- `source_environment` (string) - Origin environment
- `destination_environment` (string) - Target environment
- `created_at`, `updated_at` (datetime)

**Indexes:**
- `user_id`
- `status`
- `sync_type`
- `created_at`

**Foreign Keys:**
- `user_id` → `panda_core_users.id`

**Enums:**
- `panda_cms_sync_type`
- `panda_cms_sync_status`

**Summary Structure:**
```json
{
  "pages_added": 3,
  "pages_modified": 12,
  "pages_deleted": 0,
  "total_changes": 45,
  "contributors": 6,
  "citations_added": 8
}
```

---

## Enhanced Content Tables

### panda_cms_pages (additions)

Added contributor tracking columns to existing pages table.

**New Columns:**
- `contributor_count` (integer, default: 0) - Number of unique contributors
- `last_contributed_at` (datetime) - Last contribution date
- `workflow_status` (string, default: "draft") - Workflow state

**New Indexes:**
- `workflow_status`
- `last_contributed_at`

**Workflow Status Values:**
- `draft` - Initial creation
- `review` - Pending review
- `medical_review` - Needs specialist review
- `admin_review` - Needs admin approval
- `published` - Live

---

### panda_cms_posts (additions)

Added contributor tracking columns to existing posts table.

**New Columns:**
- `contributor_count` (integer, default: 0)
- `last_contributed_at` (datetime)
- `workflow_status` (string, default: "draft")

**New Indexes:**
- `workflow_status`
- `last_contributed_at`

---

## Relationships Diagram

```
panda_core_users
  ├── has_many :user_roles
  ├── has_many :content_versions
  ├── has_many :content_suggestions
  ├── has_many :content_comments
  └── has_many :content_sync_logs

panda_cms_roles
  └── has_many :user_roles

panda_cms_user_roles
  ├── belongs_to :user
  └── belongs_to :role

panda_cms_content_versions
  ├── belongs_to :versionable (polymorphic)
  ├── belongs_to :user
  └── has_many :content_changes

panda_cms_content_changes
  └── belongs_to :content_version

panda_cms_content_suggestions
  ├── belongs_to :suggestable (polymorphic)
  ├── belongs_to :user
  └── belongs_to :reviewed_by (User)

panda_cms_content_comments
  ├── belongs_to :commentable (polymorphic)
  ├── belongs_to :user
  ├── belongs_to :parent (Comment)
  └── belongs_to :resolved_by (User)

panda_cms_pages
  └── has_many :content_versions (as: :versionable)

panda_cms_posts
  └── has_many :content_versions (as: :versionable)
```

---

## Usage Examples

### Creating a Role
```ruby
role = Panda::CMS::Role.create!(
  name: "medical_advisor",
  description: "Reviews medical content for accuracy",
  permissions: { review_content: true, approve_medical: true },
  custom_metadata: { specialty: "mental_health" }
)
```

### Assigning a Role
```ruby
# Permanent assignment
Panda::CMS::UserRole.create!(
  user: user,
  role: reviewer_role
)

# Temporary access (expires in 7 days)
Panda::CMS::UserRole.create!(
  user: user,
  role: contributor_role,
  expires_at: 7.days.from_now
)

# One-time access token
user_role = Panda::CMS::UserRole.create!(
  role: contributor_role,
  access_token: SecureRandom.urlsafe_base64(32),
  access_token_expires_at: 7.days.from_now
)
```

### Creating a Version
```ruby
Panda::CMS::ContentVersion.create!(
  versionable: page,
  version_number: page.content_versions.count + 1,
  content: page.content,
  change_summary: "Added medical citations and updated statistics",
  user: current_user,
  source: "manual"
)
```

### Suggesting a Change
```ruby
Panda::CMS::ContentSuggestion.create!(
  suggestable: page,
  user: contributor,
  section_identifier: "symptoms-section",
  suggestion_type: "edit",
  status: "pending",
  content: "Updated symptom list based on latest DSM-5 criteria",
  rationale: "DSM-5 revised diagnostic criteria in 2022",
  requires_specialist_review: true
)
```

### Tracking Trusted Sources
```ruby
Panda::CMS::TrustedSource.create!(
  domain: "nih.gov",
  trust_level: "always_prefer",
  default_callout_type: "medical",
  notes: "National Institutes of Health - authoritative medical source"
)
```

---

## Migration Order

Migrations must be run in this order due to dependencies:

1. `20251101120000_create_panda_cms_roles.rb`
2. `20251101120001_create_panda_cms_user_roles.rb`
3. `20251101120002_create_panda_cms_content_versions.rb`
4. `20251101120003_create_panda_cms_content_changes.rb`
5. `20251101120004_create_panda_cms_content_suggestions.rb`
6. `20251101120005_create_panda_cms_content_comments.rb`
7. `20251101120006_create_panda_cms_trusted_sources.rb`
8. `20251101120007_create_panda_cms_content_sync_logs.rb`
9. `20251101120008_add_contributor_tracking_to_pages.rb`
10. `20251101120009_add_contributor_tracking_to_posts.rb`

---

## Notes

- All polymorphic associations use `type` and `id` columns
- UUIDs are generated server-side with `gen_random_uuid()`
- Enums are PostgreSQL-specific; other databases need `string` columns
- JSONB columns allow flexible metadata without schema changes
- Foreign key constraints ensure referential integrity
- Indexes optimize common queries (by status, by user, by date)
- Soft deletes not implemented; use `archived` status instead
