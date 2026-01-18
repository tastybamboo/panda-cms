# frozen_string_literal: true

module Panda
  module CMS
    # Error page component for displaying error messages
    # Used for 404, 500, and other HTTP error pages
    class ErrorPageComponent < Panda::CMS::Base
      def initialize(error_code:, message:, description: "", homepage_link: "/", **attrs)
        super()
        @error_code = error_code
        @message = message
        @description = description
        @homepage_link = homepage_link
      end

      attr_reader :error_code, :message, :description, :homepage_link
    end
  end

  def call
    render_template
  end
end
