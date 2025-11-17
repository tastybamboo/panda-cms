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
  # config.around(:each, type: :system) do |example|
  #   exception = nil

  #   # First attempt - run without debug output
  #   begin
  #     example.run
  #   rescue => e
  #     exception = e
  #   end

  #   # Also check example.exception in case RSpec aggregated exceptions there
  #   exception ||= example.exception

  #   # Handle MultipleExceptionError specially - don't retry, just report and skip
  #   if exception.is_a?(RSpec::Core::MultipleExceptionError)
  #     puts "\n" + ("=" * 80)
  #     puts "⚠️  MULTIPLE EXCEPTIONS - SKIPPING TEST (NO RETRY)"
  #     puts "=" * 80
  #     puts "Test: #{example.full_description}"
  #     puts "File: #{example.metadata[:file_path]}:#{example.metadata[:line_number]}"
  #     puts "Total exceptions: #{exception.all_exceptions.count}"
  #     puts "=" * 80

  #     # Group exceptions by class for cleaner output
  #     exceptions_by_class = exception.all_exceptions.group_by(&:class)
  #     exceptions_by_class.each do |klass, exs|
  #       puts "\n#{klass.name} (#{exs.count} occurrence#{"s" if exs.count > 1}):"
  #       puts "  #{exs.first.message.split("\n").first}"
  #     end

  #     puts "\n" + ("=" * 80)
  #     puts "⚠️  Skipping retry - moving to next test"
  #     puts "=" * 80 + "\n"

  #     # Mark this so after hooks can skip verbose output
  #     example.metadata[:multiple_exception_detected] = true

  #     # Re-raise to mark test as failed, but don't retry
  #     raise exception
  #   end

  #   # If test failed and hasn't been retried yet, retry with debug output
  #   if exception && !example.metadata[:retry_attempted]
  #     example.metadata[:retry_attempted] = true

  #     puts "\n" + ("=" * 80)
  #     puts "RETRYING FAILED TEST WITH DEBUG OUTPUT"
  #     puts "=" * 80
  #     puts "Test: #{example.full_description}"
  #     puts "File: #{example.metadata[:file_path]}:#{example.metadata[:line_number]}"
  #     puts "Original error: #{exception.class}: #{exception.message.split("\n").first}"
  #     puts "=" * 80 + "\n"

  #     # Enable debug output for retry
  #     original_debug = ENV["RSPEC_DEBUG"]
  #     ENV["RSPEC_DEBUG"] = "true"

  #     begin
  #       # Clear the exception so RSpec will re-run the test
  #       example.instance_variable_set(:@exception, nil)
  #       example.run
  #     ensure
  #       ENV["RSPEC_DEBUG"] = original_debug
  #     end
  #   elsif exception
  #     # Test failed and was already retried (or no retry needed), re-raise the exception
  #     raise exception
  #   end
  # end
end
