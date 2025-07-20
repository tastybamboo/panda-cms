# frozen_string_literal: true

module Panda
  module CMS
    class AdminConstraint
      def initialize(&block)
        @block = block
      end

      def matches?(request)
        user = current_user(request)
        puts "[DEBUG] AdminConstraint#matches? - User ID from session: #{request.session[:user_id]}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        puts "[DEBUG] AdminConstraint#matches? - Current user: #{user&.email}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        puts "[DEBUG] AdminConstraint#matches? - User present: #{user.present?}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        puts "[DEBUG] AdminConstraint#matches? - User admin: #{user&.admin?}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        result = user.present? && user.admin? && @block&.call(user)
        puts "[DEBUG] AdminConstraint#matches? - Final result: #{result}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        result
      end

      def current_user(request)
        user_id = request.session[:user_id]
        puts "[DEBUG] AdminConstraint#current_user - Looking up user ID: #{user_id}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        user = User.find_by(id: user_id)
        puts "[DEBUG] AdminConstraint#current_user - Found user: #{user&.email || 'nil'}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        user
      end
    end
  end
end
