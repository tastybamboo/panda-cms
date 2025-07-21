# frozen_string_literal: true

# Load general RSpec Rails configuration
require "rails_helper"
require "capybara/rspec"

# Load configuration files and helpers
Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |file| require file }

RSpec.configure do |config|
  config.before(:suite) do
    # Clean up old screenshots
    FileUtils.rm_rf(Rails.root.join("tmp", "capybara"))
    
    if ENV["CI"]
      puts "CI Debug - Rails environment: #{Rails.env}"
      puts "CI Debug - Database adapter: #{ActiveRecord::Base.connection.adapter_name}"
      puts "CI Debug - User count: #{Panda::CMS::User.count rescue 'error'}"
      puts "CI Debug - Page count: #{Panda::CMS::Page.count rescue 'error'}"
      puts "CI Debug - PANDA_CMS_USE_GITHUB_ASSETS: #{ENV['PANDA_CMS_USE_GITHUB_ASSETS']}"
      puts "CI Debug - Rails root: #{Rails.root}"
      puts "CI Debug - Capybara app_host: #{Capybara.app_host rescue 'not set'}"
      puts "CI Debug - Capybara server_host: #{Capybara.server_host rescue 'not set'}"
      puts "CI Debug - Capybara server_port: #{Capybara.server_port rescue 'not set'}"
      
      # Test basic Rails app functionality
      puts "CI Debug - Rails application loaded: #{Rails.application.class}"
      puts "CI Debug - Routes loaded: #{Rails.application.routes.routes.count rescue 'error'}"
      
      # Check database connection
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        puts "CI Debug - Database connection: OK"
      rescue => e
        puts "CI Debug - Database connection: ERROR - #{e.message}"
      end
    end
  end
  
  config.before(:each, type: :system) do |example|
    if ENV["CI"]
      puts "[CI Debug] Starting test: #{example.full_description}"
      
      # Check Capybara server before test
      begin
        if Capybara.current_session.server
          server = Capybara.current_session.server
          puts "[CI Debug] Capybara server running on: #{server.host}:#{server.port}"
          
          # Try to ping the server
          require 'net/http'
          uri = URI("http://#{server.host}:#{server.port}")
          response = Net::HTTP.get_response(uri)
          puts "[CI Debug] Server ping response: #{response.code} #{response.message}"
        else
          puts "[CI Debug] No Capybara server detected"
        end
      rescue => e
        puts "[CI Debug] Server check failed: #{e.class} - #{e.message}"
      end
    end
  end
end
