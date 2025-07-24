# frozen_string_literal: true

# Helper methods for Panda CMS system tests
module PandaCmsHelpers
  # Wait for Panda CMS JavaScript assets to be fully loaded
  # This ensures Stimulus controllers are registered and ready
  def wait_for_panda_cms_assets(timeout: 10)
    puts "[Test] Waiting for Panda CMS assets to load..."
    
    # Wait for the bundle to be loaded and marked as ready
    start_time = Time.now
    while Time.now - start_time < timeout
      # Check if our JavaScript bundle has loaded and initialized
      result = page.evaluate_script(<<~JS)
        window.pandaCmsLoaded === true && 
        window.Stimulus && 
        window.Stimulus.controllers && 
        window.Stimulus.controllers.size > 0
      JS
      
      if result
        puts "[Test] Panda CMS assets loaded successfully"
        return true
      end
      
      sleep 0.2
    end
    
    # Debug info if assets didn't load
    script_result = page.evaluate_script(<<~JS)
      ({
        pandaCmsLoaded: window.pandaCmsLoaded,
        pandaCmsVersion: window.pandaCmsVersion,
        stimulusExists: !!window.Stimulus,
        controllerCount: window.Stimulus ? window.Stimulus.controllers.size : 0,
        pandaCmsFullBundle: window.pandaCmsFullBundle
      })
    JS
    
    puts "[Test] Asset loading timeout. Debug info: #{script_result}"
    false
  rescue => e
    puts "[Test] Error waiting for assets: #{e.message}"
    false
  end

  # Wait for a specific element to be present with asset loading consideration
  def wait_for_element_with_assets(selector, timeout: 10)
    # First ensure assets are loaded
    wait_for_panda_cms_assets(timeout: timeout / 2)
    
    # Then wait for the element
    expect(page).to have_css(selector, wait: timeout)
  rescue RSpec::Expectations::ExpectationNotMetError => e
    puts "[Test] Element #{selector} not found. Page content length: #{page.html.length}"
    puts "[Test] Current URL: #{page.current_url}"
    raise e
  end
  
  # Debug current asset loading state
  def debug_asset_state
    result = page.evaluate_script(<<~JS)
      ({
        url: window.location.href,
        pandaCmsLoaded: window.pandaCmsLoaded,
        pandaCmsVersion: window.pandaCmsVersion,
        stimulusExists: !!window.Stimulus,
        controllerCount: window.Stimulus ? window.Stimulus.controllers.size : 0,
        pandaCmsFullBundle: window.pandaCmsFullBundle,
        documentReady: document.readyState,
        bodyClass: document.body ? document.body.className : 'no-body'
      })
    JS
    
    puts "[Test Debug] Asset state: #{result}"
    
    # Fail fast if JavaScript is not loading in CI
    if ENV["GITHUB_ACTIONS"] == "true" && result["pandaCmsLoaded"].nil?
      puts "\n❌ CRITICAL: JavaScript assets not loading in CI environment!"
      puts "   pandaCmsLoaded: #{result["pandaCmsLoaded"]}"
      puts "   stimulusExists: #{result["stimulusExists"]}"
      puts "   URL: #{result["url"]}"
      puts "\n🛑 Stopping test suite - JavaScript infrastructure is broken"
      
      # Output additional debugging information
      puts "\n📋 Debug Information:"
      puts "   Rails.env: #{Rails.env}"
      puts "   Current working directory: #{Dir.pwd}"
      
      # Check if asset files exist
      asset_path = Rails.root.join("public/panda-cms-assets/panda-cms-0.7.4.js")
      puts "   Asset file exists: #{File.exist?(asset_path)} (#{asset_path})"
      
      if File.exist?(asset_path)
        puts "   Asset file size: #{File.size(asset_path)} bytes"
        puts "   Asset file permissions: #{File.stat(asset_path).mode.to_s(8)}"
      end
      
      # Output page HTML for analysis
      html_file = Rails.root.join("tmp/capybara/javascript_failure_debug.html")
      File.write(html_file, page.html)
      puts "   Page HTML saved to: #{html_file}"
      
      fail "JavaScript assets not loading - stopping test suite to avoid wasting CI time"
    end
    
    result
  rescue => e
    puts "[Test Debug] Error getting asset state: #{e.message}"
    nil
  end
end

RSpec.configure do |config|
  config.include PandaCmsHelpers, type: :system
  
  # Add debugging to system tests
  config.before(:each, type: :system) do
    puts "[Test] Starting test: #{RSpec.current_example.full_description}"
  end
  
  config.after(:each, type: :system) do |example|
    if example.exception
      puts "[Test] Test failed: #{example.exception.message}"
      debug_asset_state
    end
  end
end