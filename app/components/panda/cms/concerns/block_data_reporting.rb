# frozen_string_literal: true

module Panda
  module CMS
    module Concerns
      # Shared error reporting for components that depend on Block/BlockContent data.
      # Reports to Rails.error (AppSignal, Sentry, etc.) without raising — the page
      # continues to render but ops gets an alert about misconfigured CMS data.
      module BlockDataReporting
        private

        # Normalize block content IDs: treat "{}" (the JSONB empty-object default
        # stored by the inline selector when nothing is selected) as nil.
        def normalize_block_content_id(raw)
          value = raw.to_s.strip
          return nil if value.blank? || value == "{}"
          return nil unless value.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
          value
        end

        def report_missing_data(detail)
          return if @editable_state

          component_name = self.class.name.demodulize
          message = "[#{component_name}] #{detail} (page: #{Current.page&.path})"
          error = Panda::CMS::MissingBlockDataError.new(message)
          Rails.error.report(error, handled: true, severity: :error, context: {
            component: self.class.name,
            key: @key,
            page_path: Current.page&.path,
            page_id: Current.page&.id,
            template_id: Current.page&.panda_cms_template_id
          })
        end
      end
    end
  end
end
