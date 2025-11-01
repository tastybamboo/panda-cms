# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class Role < ApplicationRecord
        self.table_name = "panda_cms_pro_roles"

        # Associations
        has_many :user_roles, class_name: "Panda::CMS::Pro::UserRole",
                 foreign_key: :panda_cms_pro_role_id, dependent: :destroy
        has_many :users, through: :user_roles, source: :user,
                 class_name: "Panda::Core::User"

        # Validations
        validates :name, presence: true, uniqueness: true
        validates :permissions, presence: true
        validate :validate_permissions_structure

        # Callbacks
        before_validation :set_default_permissions, on: :create

        # Scopes
        scope :system_roles, -> { where(system_role: true) }
        scope :custom_roles, -> { where(system_role: false) }
        scope :ordered, -> { order(:name) }

        # Default role names
        ADMIN = "admin"
        EDITOR = "editor"
        CONTENT_CREATOR = "content_creator"
        REVIEWER = "reviewer"
        CONTRIBUTOR = "contributor"
        VIEWER = "viewer"

        # Default permissions for each role
        DEFAULT_PERMISSIONS = {
          ADMIN => {
            create_content: true,
            edit_content: true,
            delete_content: true,
            publish_content: true,
            approve_suggestions: true,
            manage_users: true,
            manage_roles: true,
            sync_content: true,
            view_drafts: true
          },
          EDITOR => {
            create_content: true,
            edit_content: true,
            delete_content: false,
            publish_content: true,
            approve_suggestions: true,
            manage_users: false,
            manage_roles: false,
            sync_content: true,
            view_drafts: true
          },
          CONTENT_CREATOR => {
            create_content: true,
            edit_content: true,
            delete_content: false,
            publish_content: false,
            approve_suggestions: false,
            manage_users: false,
            manage_roles: false,
            sync_content: false,
            view_drafts: true
          },
          REVIEWER => {
            create_content: false,
            edit_content: false,
            delete_content: false,
            publish_content: false,
            approve_suggestions: true,
            manage_users: false,
            manage_roles: false,
            sync_content: false,
            view_drafts: true
          },
          CONTRIBUTOR => {
            create_content: false,
            edit_content: false,
            delete_content: false,
            publish_content: false,
            approve_suggestions: false,
            manage_users: false,
            manage_roles: false,
            sync_content: false,
            view_drafts: true
          },
          VIEWER => {
            create_content: false,
            edit_content: false,
            delete_content: false,
            publish_content: false,
            approve_suggestions: false,
            manage_users: false,
            manage_roles: false,
            sync_content: false,
            view_drafts: true
          }
        }.freeze

        def can?(permission)
          permissions[permission.to_s] == true
        end

        def grant(permission)
          self.permissions = permissions.merge(permission.to_s => true)
          save
        end

        def revoke(permission)
          self.permissions = permissions.merge(permission.to_s => false)
          save
        end

        def system_role?
          system_role
        end

        private

        def set_default_permissions
          self.permissions = DEFAULT_PERMISSIONS[name] || {} if permissions.blank?
        end

        def validate_permissions_structure
          return if permissions.blank?
          return if permissions.is_a?(Hash)

          errors.add(:permissions, "must be a hash")
        end
      end
    end
  end
end
