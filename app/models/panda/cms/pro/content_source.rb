# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class ContentSource < ApplicationRecord
        self.table_name = "panda_cms_pro_content_sources"

        validates :domain, presence: true, uniqueness: true
        validates :trust_level, presence: true
        validate :validate_domain_format

        enum :trust_level, {
          always_prefer: "always_prefer",
          trusted: "trusted",
          neutral: "neutral",
          untrusted: "untrusted",
          never_use: "never_use"
        }

        scope :preferred, -> { where(trust_level: :always_prefer) }
        scope :trusted_sources, -> { where(trust_level: [:always_prefer, :trusted]) }
        scope :untrusted_sources, -> { where(trust_level: [:untrusted, :never_use]) }
        scope :ordered, -> { order(trust_level: :desc, domain: :asc) }

        def matches_url?(url)
          uri = URI.parse(url)
          uri.host == domain || uri.host&.end_with?(".#{domain}")
        rescue URI::InvalidURIError
          false
        end

        def self.for_url(url)
          uri = URI.parse(url)
          domain = uri.host

          # Try exact match first
          source = find_by(domain: domain)
          return source if source

          # Try parent domains
          parts = domain.split(".")
          (parts.length - 1).downto(2) do |i|
            parent_domain = parts[i - 1..].join(".")
            source = find_by(domain: parent_domain)
            return source if source
          end

          nil
        rescue URI::InvalidURIError
          nil
        end

        def preferred?
          always_prefer?
        end

        def trustworthy?
          always_prefer? || trusted?
        end

        def avoid?
          untrusted? || never_use?
        end

        def trust_score
          case trust_level
          when "always_prefer" then 5
          when "trusted" then 4
          when "neutral" then 3
          when "untrusted" then 2
          when "never_use" then 1
          else 0
          end
        end

        private

        def validate_domain_format
          return if domain.blank?

          unless domain.match?(/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/i)
            errors.add(:domain, "is not a valid domain format")
          end

          if domain.include?("://")
            errors.add(:domain, "should be a domain only, not a full URL")
          end
        end
      end
    end
  end
end
