# frozen_string_literal: true

module Panda
  module CMS
    module Concerns
      # Shared error reporting for components that depend on Block/BlockContent data.
      # Reports to Rails.error (AppSignal, Sentry, etc.) without raising — the page
      # continues to render but ops gets an alert about misconfigured CMS data.
      module BlockDataReporting
        private

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
