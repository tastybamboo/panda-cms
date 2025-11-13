# frozen_string_literal: true

# Capture and log browser console output for debugging CI failures
module BrowserConsoleLogger
  def self.included(base)
    base.after do |example|
      # Only log console in CI when test fails
      next unless ENV["CI"] && example.exception

      if respond_to?(:page) && page.driver.is_a?(Capybara::Cuprite::Driver)
        begin
          console_logs = page.driver.browser.console_messages

          if console_logs.any?
            puts "\n" + "=" * 80
            puts "BROWSER CONSOLE OUTPUT (#{console_logs.length} messages)"
            puts "=" * 80

            console_logs.each_with_index do |msg, index|
              type_icon = case msg["type"]
              when "error" then "❌"
              when "warning" then "⚠️"
              when "info" then "ℹ️"
              else "📝"
              end

              puts "#{index + 1}. [#{msg["type"].upcase}] #{type_icon}"
              puts "   Message: #{msg["message"]}"
              puts "   Source: #{msg["source"]}" if msg["source"]
              puts "   Line: #{msg["line"]}" if msg["line"]
              puts ""
            end

            puts "=" * 80
          else
            puts "\n⚠️  No console messages captured (browser may not have started)"
          end
        rescue => e
          puts "\n⚠️  Failed to capture console logs: #{e.message}"
        end
      end
    end
  end
end

# Include in all system tests
RSpec.configure do |config|
  config.include BrowserConsoleLogger, type: :system
end
