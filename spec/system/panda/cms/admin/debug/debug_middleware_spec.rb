# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug Middleware Stack", type: :system do
  it "checks if Rack::Static is in the middleware stack" do
    # Access the Rails app's middleware stack
    middleware_stack = Rails.application.middleware.middlewares

    puts "\n" + "=" * 80
    puts "MIDDLEWARE STACK ANALYSIS"
    puts "=" * 80
    puts "\nTotal middlewares: #{middleware_stack.count}"

    # Find all Rack::Static instances
    rack_static_middlewares = middleware_stack.select { |m| m.klass == Rack::Static }

    puts "\nRack::Static instances: #{rack_static_middlewares.count}"

    rack_static_middlewares.each_with_index do |middleware, idx|
      puts "\n--- Rack::Static ##{idx + 1} ---"
      puts "Args: #{middleware.args.inspect}"
    end

    # Check if there are any middlewares that might be handling /panda requests
    puts "\n" + "-" * 80
    puts "All middlewares:"
    puts "-" * 80

    middleware_stack.each_with_index do |middleware, idx|
      puts "#{idx + 1}. #{middleware.klass}"
    end

    puts "\n" + "=" * 80

    # Also check engines
    puts "\nEngines loaded:"
    Rails::Engine.subclasses.each do |engine|
      puts "  - #{engine.name}"
    end

    puts "\n" + "=" * 80
  end
end
