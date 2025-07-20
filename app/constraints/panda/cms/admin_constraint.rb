# frozen_string_literal: true

module Panda
  module CMS
    class AdminConstraint
      def initialize(&block)
        @block = block
      end

      def matches?(request)
        user = current_user(request)
        result = user.present? && user.admin? && @block&.call(user)
        result
      end

      def current_user(request)
        user_id = request.session[:user_id]
        user = User.find_by(id: user_id)
        user
      end
    end
  end
end
