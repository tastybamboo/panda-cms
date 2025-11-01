# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class UserRole < ApplicationRecord
        self.table_name = "panda_cms_pro_user_roles"

        belongs_to :user, class_name: "Panda::Core::User"
        belongs_to :role, class_name: "Panda::CMS::Pro::Role",
                   foreign_key: :panda_cms_pro_role_id

        validates :user_id, presence: true
        validates :panda_cms_pro_role_id, presence: true
        validates :user_id, uniqueness: {scope: :panda_cms_pro_role_id}
        validate :validate_access_token_expiry

        before_create :generate_access_token, if: :needs_access_token?

        scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
        scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
        scope :with_token, -> { where.not(access_token: nil) }
        scope :permanent, -> { where(expires_at: nil) }
        scope :temporary, -> { where.not(expires_at: nil) }

        def active?
          expires_at.nil? || expires_at > Time.current
        end

        def expired?
          !active?
        end

        def token_valid?
          return false if access_token.blank? || access_token_expires_at.blank?
          access_token_expires_at > Time.current
        end

        def shareable_url(base_url)
          return nil if access_token.blank?
          "#{base_url}/access/#{access_token}"
        end

        def extend_access(duration)
          self.expires_at = (expires_at || Time.current) + duration
          save
        end

        def extend_token(duration)
          self.access_token_expires_at = (access_token_expires_at || Time.current) + duration
          save
        end

        def revoke!
          self.expires_at = Time.current
          self.access_token_expires_at = Time.current if access_token.present?
          save
        end

        private

        def needs_access_token?
          access_token.blank? && access_token_expires_at.present?
        end

        def generate_access_token
          self.access_token = SecureRandom.urlsafe_base64(32)
        end

        def validate_access_token_expiry
          return if access_token.blank?
          return if access_token_expires_at.present?
          errors.add(:access_token_expires_at, "must be set when access_token is present")
        end
      end
    end
  end
end
