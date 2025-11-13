# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug Module Registry", type: :system do
  it "checks registered modules" do
    puts "\n" + "=" * 80
    puts "MODULE REGISTRY STATUS"
    puts "=" * 80

    modules = Panda::Core::ModuleRegistry.modules

    puts "\nRegistered modules: #{modules.count}"

    modules.each do |gem_name, info|
      puts "\n--- #{gem_name} ---"
      puts "Engine: #{info[:engine]}"
      puts "Available: #{Panda::Core::ModuleRegistry.send(:engine_available?, info[:engine])}"

      if Panda::Core::ModuleRegistry.send(:engine_available?, info[:engine])
        root = Panda::Core::ModuleRegistry.send(:engine_root, info[:engine])
        puts "Root: #{root}"

        # Check JavaScript directory
        js_dir = root.join("app/javascript/panda")
        puts "JS dir exists: #{js_dir.directory?}"

        if js_dir.directory?
          puts "JS dir contents:"
          js_dir.children.select(&:directory?).each do |subdir|
            puts "  - #{subdir.basename}/"
          end
        end
      end
    end

    puts "\n" + "=" * 80
  end
end
