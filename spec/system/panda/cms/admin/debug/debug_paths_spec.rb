# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug Rack::Static Paths", type: :system do
  it "checks path resolution" do
    # Check what Rack::Static is configured with
    middleware_stack = Rails.application.middleware.middlewares
    rack_static_middlewares = middleware_stack.select { |m| m.klass == Rack::Static }

    puts "\n" + "=" * 80
    puts "RACK::STATIC PATH ANALYSIS"
    puts "=" * 80

    rack_static_middlewares.each_with_index do |middleware, idx|
      args = middleware.args.first
      next unless args[:urls]&.include?("/panda")

      urls = args[:urls]
      root = args[:root]

      puts "\n--- Rack::Static ##{idx + 1} (serving /panda) ---"
      puts "URLs: #{urls.inspect}"
      puts "Root: #{root}"
      puts "Root exists? #{File.directory?(root)}"
      puts "Root is absolute? #{root.absolute?}"

      # Check what files are in the root
      if File.directory?(root)
        puts "\nContents of root:"
        Dir.entries(root).each do |entry|
          next if entry.start_with?(".")
          full_path = root.join(entry)
          if File.directory?(full_path)
            puts "  [DIR]  #{entry}/"
          else
            puts "  [FILE] #{entry}"
          end
        end

        # Check for the specific files we're looking for
        test_paths = [
          "cms/application.js",
          "core/application.js"
        ]

        puts "\nLooking for expected files:"
        test_paths.each do |rel_path|
          full_path = root.join(rel_path)
          exists = File.exist?(full_path)
          puts "  #{rel_path}: #{exists ? "✅ EXISTS" : "❌ MISSING"}"
          puts "    Full path: #{full_path}" if exists
        end
      end
    end

    puts "\n" + "=" * 80
  end
end
