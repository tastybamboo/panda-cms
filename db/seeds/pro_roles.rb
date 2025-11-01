# frozen_string_literal: true

# Seed default roles for Panda CMS Pro
#
# This creates the standard role hierarchy with appropriate permissions
# for content management workflows.

puts "Creating Panda CMS Pro default roles..."

# Admin - Full access to everything
Panda::CMS::Pro::Role.find_or_create_by!(name: Panda::CMS::Pro::Role::ADMIN) do |role|
  role.description = "Full administrative access to all Pro features"
  role.permissions = {
    create_content: true,
    edit_content: true,
    delete_content: true,
    publish_content: true,
    manage_suggestions: true,
    approve_suggestions: true,
    manage_comments: true,
    manage_versions: true,
    restore_versions: true,
    manage_roles: true,
    manage_users: true,
    sync_content: true,
    manage_sources: true,
    view_analytics: true
  }
  role.system_role = true
end

# Editor - Can create, edit, and publish content
Panda::CMS::Pro::Role.find_or_create_by!(name: Panda::CMS::Pro::Role::EDITOR) do |role|
  role.description = "Can create, edit, and publish content with approval workflow"
  role.permissions = {
    create_content: true,
    edit_content: true,
    delete_content: false,
    publish_content: true,
    manage_suggestions: true,
    approve_suggestions: true,
    manage_comments: true,
    manage_versions: true,
    restore_versions: true,
    manage_roles: false,
    manage_users: false,
    sync_content: false,
    manage_sources: false,
    view_analytics: true
  }
  role.system_role = true
end

# Content Creator - Can create and edit content, needs approval to publish
Panda::CMS::Pro::Role.find_or_create_by!(name: Panda::CMS::Pro::Role::CONTENT_CREATOR) do |role|
  role.description = "Can create and edit content, but requires approval to publish"
  role.permissions = {
    create_content: true,
    edit_content: true,
    delete_content: false,
    publish_content: false,
    manage_suggestions: false,
    approve_suggestions: false,
    manage_comments: true,
    manage_versions: false,
    restore_versions: false,
    manage_roles: false,
    manage_users: false,
    sync_content: false,
    manage_sources: false,
    view_analytics: false
  }
  role.system_role = true
end

# Reviewer - Can review and approve suggestions
Panda::CMS::Pro::Role.find_or_create_by!(name: Panda::CMS::Pro::Role::REVIEWER) do |role|
  role.description = "Can review content suggestions and provide specialist feedback"
  role.permissions = {
    create_content: false,
    edit_content: false,
    delete_content: false,
    publish_content: false,
    manage_suggestions: true,
    approve_suggestions: true,
    manage_comments: true,
    manage_versions: false,
    restore_versions: false,
    manage_roles: false,
    manage_users: false,
    sync_content: false,
    manage_sources: false,
    view_analytics: false
  }
  role.system_role = true
end

# Contributor - Can make suggestions and comments (often one-time access)
Panda::CMS::Pro::Role.find_or_create_by!(name: Panda::CMS::Pro::Role::CONTRIBUTOR) do |role|
  role.description = "Can make suggestions and comments on content"
  role.permissions = {
    create_content: false,
    edit_content: false,
    delete_content: false,
    publish_content: false,
    manage_suggestions: false,
    approve_suggestions: false,
    manage_comments: false,
    manage_versions: false,
    restore_versions: false,
    manage_roles: false,
    manage_users: false,
    sync_content: false,
    manage_sources: false,
    view_analytics: false
  }
  role.system_role = true
end

# Viewer - Read-only access
Panda::CMS::Pro::Role.find_or_create_by!(name: Panda::CMS::Pro::Role::VIEWER) do |role|
  role.description = "Read-only access to content and versions"
  role.permissions = {
    create_content: false,
    edit_content: false,
    delete_content: false,
    publish_content: false,
    manage_suggestions: false,
    approve_suggestions: false,
    manage_comments: false,
    manage_versions: false,
    restore_versions: false,
    manage_roles: false,
    manage_users: false,
    sync_content: false,
    manage_sources: false,
    view_analytics: false
  }
  role.system_role = true
end

puts "✓ Created #{Panda::CMS::Pro::Role.count} default roles"
