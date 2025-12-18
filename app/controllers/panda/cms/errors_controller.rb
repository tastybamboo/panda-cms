# frozen_string_literal: true

module Panda
  module CMS
    class ErrorsController < ApplicationController
      layout "error"

      skip_before_action :set_current_request_details
      skip_before_action :verify_authenticity_token

      def show
        status_code = determine_status_code
        render view_for_code(status_code), status: status_code, content_type: "text/html"
      end

      def error_503
        render view_for_code(503), status: 503
      end

      private

      def determine_status_code
        # First check if there's a code from the route params (direct access)
        return params[:code].to_i if params[:code].present?

        # Otherwise, try to get it from the exception (exceptions_app flow)
        exception = request.env["action_dispatch.exception"]
        return 404 unless exception

        if exception.respond_to?(:status_code)
          exception.status_code
        else
          ActionDispatch::ExceptionWrapper.new(request.env, exception).status_code
        end
      end

      def view_for_code(code)
        supported_error_codes.fetch(code, "404")
      end

      def supported_error_codes
        {
          403 => "403",
          404 => "404",
          422 => "422",
          500 => "500",
          503 => "503"
        }
      end
    end
  end
end
