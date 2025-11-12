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
  end

  # Enable automatic retry with debug output for failed system tests
  config.around(:each, type: :system) do |example|
    exception = nil

    # First attempt - run without debug output
    begin
      example.run
    rescue => e
      exception = e
    end

    # If test failed and hasn't been retried yet, retry with debug output
    if exception && !example.metadata[:retry_attempted]
      example.metadata[:retry_attempted] = true

      puts "\n" + ("=" * 80)
      puts "RETRYING FAILED TEST WITH DEBUG OUTPUT"
      puts "=" * 80
      puts "Test: #{example.full_description}"
      puts "File: #{example.metadata[:file_path]}:#{example.metadata[:line_number]}"
      puts "Original error: #{exception.class}: #{exception.message.split("\n").first}"
      puts "=" * 80 + "\n"

      # Enable debug output for retry
      original_debug = ENV["RSPEC_DEBUG"]
      ENV["RSPEC_DEBUG"] = "true"

      begin
        # Clear the exception so RSpec will re-run the test
        example.instance_variable_set(:@exception, nil)
        example.run
      ensure
        ENV["RSPEC_DEBUG"] = original_debug
      end
    elsif exception
      # Already retried, re-raise the exception
      raise exception
    end
  end
end
