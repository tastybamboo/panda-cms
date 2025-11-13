# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug File Access", type: :system do
  fixtures :all

  before do
    login_as_admin
  end

  it "checks if module files are accessible" do
    driven_by(:cuprite)

    visit edit_admin_cms_page_path(panda_cms_pages(:about_page))
    sleep 2

    puts "\n" + "=" * 80
    puts "CHECKING ES MODULE SHIMS"
    puts "=" * 80

    # Check for ES module shims script tag
    html = page.html
    if html.include?("es-module-shims")
      puts "  ✅ es-module-shims script tag found"
    else
      puts "  ❌ es-module-shims script tag NOT found"
    end

    # Check if it's loaded
    shim_check = page.evaluate_script(<<~JS)
      {
        shimExists: typeof window.importShim !== 'undefined',
        esmsInitOptions: typeof window.esmsInitOptions !== 'undefined',
        hasImportmap: !!document.querySelector('script[type="importmap"]')
      }
    JS

    puts "  importShim available: #{shim_check["shimExists"]}"
    puts "  esmsInitOptions available: #{shim_check["esmsInitOptions"]}"
    puts "  Importmap tag in DOM: #{shim_check["hasImportmap"]}"

    puts "\n" + "=" * 80
    puts "TESTING DIRECT FILE ACCESS"
    puts "=" * 80

    # Get the current host
    current_url = URI.parse(page.current_url)
    base_url = "#{current_url.scheme}://#{current_url.host}:#{current_url.port}"

    puts "\nBase URL: #{base_url}"

    # Test files with direct navigation
    test_files = [
      "/panda/cms/application.js",
      "/panda/core/application.js"
    ]

    test_files.each do |file_path|
      puts "\n  Testing: #{file_path}"

      begin
        # Navigate directly to the file
        visit "#{base_url}#{file_path}"
        sleep 0.5

        # Check status code and content
        status_code = page.status_code
        content_length = page.html.length
        content_preview = page.html[0..200]

        puts "    Status: #{status_code}"
        puts "    Content length: #{content_length} bytes"
        puts "    Preview: #{content_preview[0..100]}..."

        if status_code == 200 && content_length > 0
          puts "    ✅ FILE ACCESSIBLE"
        else
          puts "    ❌ FILE NOT ACCESSIBLE"
        end
      rescue => e
        puts "    ❌ ERROR: #{e.message}"
      end
    end

    # Return to edit page
    visit edit_admin_cms_page_path(panda_cms_pages(:about_page))
    sleep 1

    puts "\n" + "=" * 80
    puts "CHECKING CONSOLE ERRORS"
    puts "=" * 80

    # Try to get console logs
    logs = page.driver.browser.console.messages
    if logs && !logs.empty?
      puts "\nConsole messages:"
      logs.each do |log|
        puts "  [#{log.level}] #{log.text}"
      end
    else
      puts "  No console messages captured (or console not accessible)"
    end

    puts "\n" + "=" * 80
  end
end
