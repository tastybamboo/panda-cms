# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug Module Loading", type: :system do
  fixtures :all

  before do
    login_as_admin
  end

  it "checks module paths and content" do
    driven_by(:cuprite)

    visit edit_admin_cms_page_path(panda_cms_pages(:about_page))

    # Wait for page to settle
    sleep 2

    puts "\n#{"=" * 80}"
    puts "MODULE PATH ANALYSIS"
    puts "=" * 80

    # Check what's in the page HTML
    html = page.html

    # Extract importmap content
    if html =~ %r{<script type="importmap"[^>]*>(.*?)</script>}m
      importmap_content = Regexp.last_match(1)
      puts "\n✅ Found importmap in HTML:"
      puts importmap_content[0..500]
    else
      puts "\n❌ No importmap found in HTML"
    end

    # Check for module script tags
    module_scripts = html.scan(%r{<script[^>]*type="module"[^>]*>([^<]+)</script>})
    puts "\n\nModule Script Tags (#{module_scripts.count} found):"
    module_scripts.each do |script|
      puts "  - #{script.first.strip}"
    end

    # Try to directly request the critical module paths
    critical_paths = [
      "/panda/cms/application.js",
      "/panda/cms/controllers/index.js",
      "/panda/core/application.js",
      "/panda/core/controllers/index.js"
    ]

    puts "\n#{"-" * 80}"
    puts "DIRECT MODULE ACCESS TEST:"
    puts "-" * 80

    critical_paths.each do |path|
      # Use page.driver to make a direct HTTP request
      response = page.driver.browser.network.response(
        url: page.driver.browser.base_url + path
      )

      puts "\n  #{path}"
      if response
        puts "  Status: #{response.status}"
        puts "  ✅ ACCESSIBLE"
      else
        puts "  ❌ NO RESPONSE"
      end
    rescue => e
      puts "\n  #{path}"
      puts "  ❌ ERROR: #{e.message}"
    end

    # Check what Stimulus sees
    stimulus_info = page.evaluate_script(<<~JS)
      {
        stimulusExists: typeof window.Stimulus !== 'undefined',
        pandaCoreApplication: typeof window.pandaCoreApplication !== 'undefined',
        pandaCmsApplication: typeof window.pandaCmsApplication !== 'undefined',
        controllers: window.Stimulus ? Object.keys(window.Stimulus.router.modulesByIdentifier) : [],
        importmapShimReady: typeof window.importShim !== 'undefined'
      }
    JS

    puts "\n#{"-" * 80}"
    puts "BROWSER JAVASCRIPT STATE:"
    puts "-" * 80
    puts "  Stimulus exists: #{stimulus_info["stimulusExists"]}"
    puts "  pandaCoreApplication exists: #{stimulus_info["pandaCoreApplication"]}"
    puts "  pandaCmsApplication exists: #{stimulus_info["pandaCmsApplication"]}"
    puts "  Importmap shim ready: #{stimulus_info["importmapShimReady"]}"
    puts "  Registered controllers: #{stimulus_info["controllers"].inspect}"

    puts "\n#{"=" * 80}"
  end
end
