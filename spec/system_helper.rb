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
    end
  end
end
