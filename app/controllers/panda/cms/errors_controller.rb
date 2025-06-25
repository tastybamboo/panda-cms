# frozen_string_literal: true

module Panda
  module CMS
    class ErrorsController < ApplicationController
      layout "error"

      def show
        exception = request.env["action_dispatch.exception"]
        status_code = exception.try(:status_code) || ActionDispatch::ExceptionWrapper.new(request.env,
          exception).status_code

        render view_for_code(status_code), status: status_code
      end

      def error_503
        render view_for_code(503), status: 503
      end

      private

      def view_for_code(code)
        supported_error_codes.fetch(code, "404")
      end

      def supported_error_codes
        {
          403 => "403",
          404 => "404",
          500 => "500",
          503 => "503"
        }
      end
    end
  end
end
