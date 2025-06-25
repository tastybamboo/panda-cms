# frozen_string_literal: true

module Panda
  module CMS
    class AdminConstraint
      def initialize(&block)
        @block = block
      end

      def matches?(request)
        user = current_user(request)
        user.present? && user.admin? && @block&.call(user)
      end

      def current_user(request)
        User.find_by(id: request.session[:user_id])
      end
    end
  end
end
