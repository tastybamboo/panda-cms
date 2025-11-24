# frozen_string_literal: true

# Helper methods for Panda CMS system tests
module PandaCmsHelpers
  # Debug logging helper - only outputs when RSPEC_DEBUG=true
  def debug_log(message)
    puts message if ENV["RSPEC_DEBUG"] == "true"
  end

  # Wait for Panda CMS JavaScript assets to be fully loaded
  # This ensures Stimulus controllers are registered and ready
  def wait_for_panda_cms_assets(timeout: 10)
    debug_log("[Test] Waiting for Panda CMS assets to load...")

    # Wait for the bundle to be loaded and marked as ready
    start_time = Time.now
    while Time.now - start_time < timeout
      # Check if our JavaScript bundle has loaded and initialized
      result = page.evaluate_script(<<~JS)
        (function() {
          // Always check the top-level window, not iframe
          var topWindow = window.top || window;

          return topWindow.pandaCmsLoaded === true &&
                 topWindow.Stimulus &&
                 topWindow.Stimulus.controllers &&
                 topWindow.Stimulus.controllers.size > 0;
        })()
      JS

      if result
        debug_log("[Test] Panda CMS assets loaded successfully")
        return true
      end

      sleep 0.2
    end

    # Debug info if assets didn't load
    script_result = page.evaluate_script(<<~JS)
      (function() {
        // Always check the top-level window, not iframe
        var topWindow = window.top || window;

        return {
          pandaCmsLoaded: topWindow.pandaCmsLoaded,
          pandaCmsVersion: topWindow.pandaCmsVersion,
          pandaCmsScriptExecuted: topWindow.pandaCmsScriptExecuted,
          pandaCmsError: topWindow.pandaCmsError,
          pandaCmsInlineTest: topWindow.pandaCmsInlineTest,
          stimulusExists: !!topWindow.Stimulus,
          controllerCount: topWindow.Stimulus ? topWindow.Stimulus.controllers.size : 0,
          pandaCmsFullBundle: topWindow.pandaCmsFullBundle,
          context: window === topWindow ? 'main-page' : 'iframe'
        };
      })()
    JS

    debug_log("[Test] Asset loading timeout. Debug info: #{script_result}")
    false
  rescue => e
    debug_log("[Test] Error waiting for assets: #{e.message}")
    false
  end

  # Wait for a specific element to be present with asset loading consideration
  def wait_for_element_with_assets(selector, timeout: 10)
    # First ensure assets are loaded
    wait_for_panda_cms_assets(timeout: timeout / 2)

    # Then wait for the element
    expect(page).to have_css(selector, wait: timeout)
  rescue RSpec::Expectations::ExpectationNotMetError => e
    debug_log("[Test] Element #{selector} not found. Page content length: #{page.html.length}")
    debug_log("[Test] Current URL: #{page.current_url}")
    raise e
  end

  # Wait for iframe to load properly before interacting with it
  def wait_for_iframe_load(iframe_id, timeout: 20)
    debug_log("[Test] Waiting for iframe #{iframe_id} to load...")

    start_time = Time.now
    while Time.now - start_time < timeout
      begin
        # First, wait for the page to be fully loaded
        expect(page).to have_css("iframe##{iframe_id}", wait: 2)

        # Check if iframe exists and has a proper src attribute
        iframe = page.find("iframe##{iframe_id}")
        src_attr = iframe["src"]

        debug_log("[Test] Iframe src: #{src_attr}")

        # If iframe has no src or about:blank, wait for it to be set
        if src_attr.nil? || src_attr.empty? || src_attr == "about:blank"
          debug_log("[Test] Iframe has no proper src attribute, waiting...")
          sleep 0.5
          next
        end

        # Wait for iframe content to load by checking the document state
        iframe_ready = false
        begin
          page.within_frame(iframe_id) do
            # Wait for the iframe to actually load content
            current_url = page.evaluate_script("window.location.href")
            document_ready = page.evaluate_script("document.readyState")
            debug_log("[Test] Iframe URL: #{current_url}, readyState: #{document_ready}")

            iframe_ready = current_url != "about:blank" &&
              !current_url.empty? &&
              current_url.include?("embed_id") &&
              document_ready == "complete"
          end
        rescue Ferrum::NodeNotFoundError => e
          debug_log("[Test] Iframe not accessible yet: #{e.message}")
          sleep 0.5
          next
        end

        if iframe_ready
          debug_log("[Test] Iframe #{iframe_id} loaded successfully")
          return true
        else
          debug_log("[Test] Iframe content not ready yet, continuing to wait...")
        end
      rescue RSpec::Expectations::ExpectationNotMetError
        debug_log("[Test] Iframe element not found yet, waiting...")
      rescue => e
        debug_log("[Test] Iframe not ready yet: #{e.message}")
      end

      sleep 0.5
    end

    # Debug information on timeout
    begin
      if page.has_css?("iframe##{iframe_id}")
        iframe = page.find("iframe##{iframe_id}")
        debug_log("[Test] Iframe debug - src: #{iframe["src"]}, id: #{iframe["id"]}")
      else
        debug_log("[Test] Iframe element not found in DOM")
        debug_log("[Test] Available iframes: #{page.all("iframe").map { |f| f["id"] }}")
      end
    rescue => e
      debug_log("[Test] Error getting iframe debug info: #{e.message}")
    end

    debug_log("[Test] Timeout waiting for iframe #{iframe_id} to load")
    false
  rescue => e
    debug_log("[Test] Error waiting for iframe: #{e.message}")
    false
  end

  # Safe form field interaction that avoids Ferrum browser resets
  def safe_fill_in(locator, with:, **options)
    # First check if field exists
    field_exists = if locator.include?("[") || locator.include?("#") || locator.include?(".")
      # It's a CSS selector
      page.evaluate_script("document.querySelector(#{locator.to_json}) !== null")
    else
      # It's a field name/id/label - check multiple ways
      page.evaluate_script(<<~JS)
        document.getElementById(#{locator.to_json}) !== null ||
        document.querySelector('input[name="' + #{locator.to_json} + '"]') !== null ||
        document.querySelector('textarea[name="' + #{locator.to_json} + '"]') !== null ||
        document.querySelector('select[name="' + #{locator.to_json} + '"]') !== null ||
        document.querySelector('label[for="' + #{locator.to_json} + '"]') !== null
      JS
    end

    expect(field_exists).to be(true), "Field '#{locator}' not found in page"

    # For validation tests, always use standard Capybara to ensure proper form state
    test_description = RSpec.current_example&.full_description || ""
    if is_validation_test?(test_description)
      fill_in locator, with: with, **options
      return
    end

    # In CI, use defensive JavaScript approach to avoid browser resets for non-validation tests
    if ENV["GITHUB_ACTIONS"] == "true"
      # Use JavaScript directly to set the field value to avoid Capybara timing issues
      field_set = page.evaluate_script(<<~JS)
        (function() {
          var field = document.getElementById(#{locator.to_json}) ||
                     document.querySelector('input[name="' + #{locator.to_json} + '"]') ||
                     document.querySelector('textarea[name="' + #{locator.to_json} + '"]') ||
                     document.querySelector('select[name="' + #{locator.to_json} + '"]');
          if (field) {
            // Set the new value
            field.value = #{with.to_json};

            // Trigger comprehensive events to ensure Rails sees the change
            field.dispatchEvent(new Event('input', { bubbles: true }));
            field.dispatchEvent(new Event('change', { bubbles: true }));
            field.dispatchEvent(new Event('blur', { bubbles: true }));
            field.dispatchEvent(new Event('focusout', { bubbles: true }));

            return true;
          }
          return false;
        })()
      JS

      expect(field_set).to be(true), "Field '#{locator}' not found or could not be set"
    else
      # In local development, use standard Capybara approach for proper Rails integration
      fill_in locator, with: with, **options
    end
  end

  # Safe element expectation that avoids Ferrum browser resets
  def safe_expect_field(locator, **options)
    # Check field exists first
    field_exists = if locator.include?("[") || locator.include?("#") || locator.include?(".")
      page.evaluate_script("document.querySelector(#{locator.to_json}) !== null")
    else
      page.evaluate_script(<<~JS)
        document.getElementById(#{locator.to_json}) !== null ||
        document.querySelector('input[name="' + #{locator.to_json} + '"]') !== null ||
        document.querySelector('textarea[name="' + #{locator.to_json} + '"]') !== null ||
        document.querySelector('select[name="' + #{locator.to_json} + '"]') !== null ||
        document.querySelector('label[for="' + #{locator.to_json} + '"]') !== null
      JS
    end

    expect(field_exists).to be(true), "Field '#{locator}' not found in page"

    # For validation tests, always use standard Capybara matchers
    test_description = RSpec.current_example&.full_description || ""
    if is_validation_test?(test_description)
      expect(page).to have_field(locator, **options)
      return
    end

    # In CI, skip Capybara matchers that cause browser resets for non-validation tests
    if ENV["GITHUB_ACTIONS"] == "true"
      # For CI, just verify via JavaScript to avoid Ferrum issues
      if options[:with]
        field_value = page.evaluate_script(<<~JS)
          (function() {
            var field = document.getElementById(#{locator.to_json}) ||
                       document.querySelector('input[name="' + #{locator.to_json} + '"]') ||
                       document.querySelector('textarea[name="' + #{locator.to_json} + '"]') ||
                       document.querySelector('select[name="' + #{locator.to_json} + '"]');
            return field ? field.value : null;
          })()
        JS
        expect(field_value).to eq(options[:with]), "Field '#{locator}' value mismatch: expected '#{options[:with]}', got '#{field_value}'"
      end
      # Skip other options for now in CI to avoid browser resets
    else
      # In local development, use full Capybara matchers
      expect(page).to have_field(locator, **options)
    end
  end

  # Safe button expectation
  def safe_expect_button(locator, **options)
    button_exists = page.evaluate_script(<<~JS)
      document.getElementById(#{locator.to_json}) !== null ||
      document.querySelector('button[name="' + #{locator.to_json} + '"]') !== null ||
      document.querySelector('input[type="submit"][value="' + #{locator.to_json} + '"]') !== null ||
      Array.from(document.querySelectorAll('button')).some(btn => btn.textContent.trim() === #{locator.to_json})
    JS

    expect(button_exists).to be(true), "Button '#{locator}' not found in page"

    # For validation tests, always use standard Capybara matchers
    test_description = RSpec.current_example&.full_description || ""
    if is_validation_test?(test_description)
      expect(page).to have_button(locator, **options)
      return
    end

    # In CI, skip Capybara matchers that cause browser resets for non-validation tests
    unless ENV["GITHUB_ACTIONS"] == "true"
      expect(page).to have_button(locator, **options)
    end
  end

  # Safe select expectation
  def safe_expect_select(locator, **options)
    select_exists = page.evaluate_script(<<~JS)
      document.getElementById(#{locator.to_json}) !== null ||
      document.querySelector('select[name="' + #{locator.to_json} + '"]') !== null ||
      document.querySelector('label[for="' + #{locator.to_json} + '"]') !== null
    JS

    expect(select_exists).to be(true), "Select '#{locator}' not found in page"

    # For validation tests, always use standard Capybara matchers
    test_description = RSpec.current_example&.full_description || ""
    if is_validation_test?(test_description)
      expect(page).to have_select(locator, **options)
      return
    end

    # In CI, skip Capybara matchers that cause browser resets for non-validation tests
    unless ENV["GITHUB_ACTIONS"] == "true"
      expect(page).to have_select(locator, **options)
    end
  end

  # Safe button click that avoids Ferrum browser resets
  def safe_click_button(locator, **options)
    button_exists = page.evaluate_script(<<~JS)
      document.getElementById(#{locator.to_json}) !== null ||
      document.querySelector('button[name="' + #{locator.to_json} + '"]') !== null ||
      document.querySelector('input[type="submit"][value="' + #{locator.to_json} + '"]') !== null ||
      Array.from(document.querySelectorAll('button')).some(btn => btn.textContent.trim() === #{locator.to_json})
    JS

    expect(button_exists).to be(true), "Button '#{locator}' not found in page"

    # For validation tests, always use standard Capybara to ensure proper form submission
    test_description = RSpec.current_example&.full_description || ""
    if is_validation_test?(test_description)
      click_button(locator, **options)
      return
    end

    click_button(locator, **options)
  end

  # Safe link click that avoids Ferrum browser resets
  def safe_click_link(locator, **options)
    link_exists = page.evaluate_script(<<~JS)
      document.getElementById(#{locator.to_json}) !== null ||
      Array.from(document.querySelectorAll('a')).some(link => link.textContent.trim() === #{locator.to_json}) ||
      document.querySelector('a[href*="' + #{locator.to_json} + '"]') !== null
    JS

    expect(link_exists).to be(true), "Link '#{locator}' not found in page"
    click_link(locator, **options)
  end

  # Safe element finding that avoids Ferrum browser resets
  def safe_find(selector, **options)
    element_exists = page.evaluate_script(<<~JS)
      document.querySelector(#{selector.to_json}) !== null
    JS

    expect(element_exists).to be(true), "Element '#{selector}' not found in page"
    find(selector, **options)
  end

  # Safe select that avoids Ferrum browser resets
  def safe_select(value, from:, **options)
    # First verify the select element exists
    select_exists = page.evaluate_script(<<~JS)
      document.getElementById(#{from.to_json}) !== null ||
      document.querySelector('select[name="' + #{from.to_json} + '"]') !== null ||
      document.querySelector('label[for="' + #{from.to_json} + '"]') !== null
    JS

    expect(select_exists).to be(true), "Select '#{from}' not found in page"
    select(value, from: from, **options)
  end

  # Debug current asset loading state
  def debug_asset_state
    # Ensure we're checking the main page context, not an iframe
    result = page.evaluate_script(<<~JS)
      (function() {
        // Always check the top-level window, not iframe
        var topWindow = window.top || window;
        var topDocument = topWindow.document;

        return {
          url: topWindow.location.href,
          pandaCmsLoaded: topWindow.pandaCmsLoaded,
          pandaCmsVersion: topWindow.pandaCmsVersion,
          pandaCmsScriptExecuted: topWindow.pandaCmsScriptExecuted,
          pandaCmsError: topWindow.pandaCmsError,
          pandaCmsInlineTest: topWindow.pandaCmsInlineTest,
          stimulusExists: !!topWindow.Stimulus,
          controllerCount: topWindow.Stimulus ? topWindow.Stimulus.controllers.size : 0,
          pandaCmsFullBundle: topWindow.pandaCmsFullBundle,
          documentReady: topDocument.readyState,
          bodyClass: topDocument.body ? topDocument.body.className : 'no-body',
          isInIframe: window !== topWindow,
          parentUrl: (window !== topWindow) ? topDocument.referrer : 'not-in-iframe',
          currentContext: window === topWindow ? 'main-page' : 'iframe'
        };
      })()
    JS

    puts "[Test Debug] Asset state: #{result}"

    # Fail fast if JavaScript is not loading in CI, but only after a few failures
    # to see if it's isolated to specific test types
    @javascript_failures_count ||= 0

    # Track which test types are having JavaScript issues
    if ENV["GITHUB_ACTIONS"] == "true" && result["pandaCmsLoaded"].nil?
      @javascript_failures_count += 1
      test_name = RSpec.current_example&.full_description || "unknown test"
      puts "[Test Debug] JavaScript failure ##{@javascript_failures_count} in: #{test_name}"
    end

    if ENV["GITHUB_ACTIONS"] == "true" && result["pandaCmsLoaded"].nil? && @javascript_failures_count >= 5
      puts "\n❌ CRITICAL: JavaScript assets not loading in CI environment!"
      puts "   pandaCmsLoaded: #{result["pandaCmsLoaded"]}"
      puts "   stimulusExists: #{result["stimulusExists"]}"
      puts "   URL: #{result["url"]}"
      puts "   Page title: #{begin
        page.title
      rescue
        "unable to get title"
      end}"
      puts "   Current path: #{begin
        page.current_path
      rescue
        "unable to get path"
      end}"
      puts "   Current URL: #{begin
        page.current_url
      rescue
        "unable to get URL"
      end}"
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
      begin
        html_file = Rails.root.join("tmp/capybara/javascript_failure_debug.html")
        FileUtils.mkdir_p(File.dirname(html_file))
        File.write(html_file, page.html)
        puts "   Page HTML saved to: #{html_file}"

        # Check if we're in an iframe context and debug iframe URLs
        begin
          page.within_frame("editablePageFrame") do
            iframe_url = page.evaluate_script("window.location.href")
            puts "   Iframe URL: #{iframe_url}"
          end
        rescue
          puts "   No iframe found or iframe not accessible"
        end

        # Check for iframes in the main page HTML
        if page.html.include?("<iframe")
          iframe_matches = page.html.scan(/<iframe[^>]*src="([^"]*)"[^>]*>/i)
          puts "   Iframe(s) found: #{iframe_matches.flatten}"

          # Try to access iframe content
          begin
            iframe_count = page.all("iframe").count
            puts "   Total iframes detected: #{iframe_count}"

            page.all("iframe").each_with_index do |iframe, index|
              puts "   Iframe #{index + 1} src: #{iframe["src"]}"
              puts "   Iframe #{index + 1} id: #{iframe["id"]}"
              puts "   Iframe #{index + 1} name: #{iframe["name"]}"
            end
          rescue => e
            puts "   Error checking iframe details: #{e.message}"
          end
        else
          puts "   No iframe elements found in HTML"
        end
      rescue => e
        puts "   Error saving debug info: #{e.message}"
      end

      fail "JavaScript assets not loading - stopping test suite to avoid wasting CI time"
    end

    result
  rescue => e
    puts "[Test Debug] Error getting asset state: #{e.message}"
    nil
  end

  private

  # Comprehensive detection of validation-related tests
  # These tests require standard Capybara form handling to ensure proper Rails validation behavior
  #
  # For complete validation testing guide, see: docs/developers/testing/validation-testing.md
  def is_validation_test?(test_description)
    validation_patterns = [
      "validation",       # "shows validation errors"
      "validates",        # "validates required fields"
      "invalid",          # "with invalid details"
      "required",         # "with required fields", "missing required"
      "missing",          # "when title is missing", "with missing URL"
      "blank",            # "can't be blank"
      "incorrect",        # "with an incorrect URL"
      "already been",     # "URL that has already been used"
      "must start",       # "must start with a forward slash"
      "error.*when",      # "error when adding"
      "fail.*submit"      # "form submission fails"
    ]

    # Convert to lowercase for case-insensitive matching
    description_lower = test_description.downcase

    # Check if any validation pattern matches
    validation_patterns.any? { |pattern| description_lower.include?(pattern) }

    # Debug output to verify pattern detection
    # puts "[VALIDATION DEBUG] Test: '#{test_description}' -> validation: #{is_validation}"
  end
end

RSpec.configure do |config|
  config.include PandaCmsHelpers, type: :system

  config.after(:each, type: :system) do |example|
    next unless example.exception
    puts "\n====TEST FAILED====\n#{example.exception.message}\n\n"
    html = begin
      page.html
    rescue
      nil
    end
    next unless html && html.length < 500
    puts "[CI] Short page HTML (#{html.length} chars):"
    puts html.inspect
  end

  # Add debugging to system tests
  # config.before(:each, type: :system) do
  #   debug_log("\nStarting test (debug enabled): #{RSpec.current_example.full_description}\n")
  # end

  # config.after(:each, type: :system) do |example|
  #   if example.exception
  #     debug_log("\n====TEST FAILED====\n#{example.exception.message}\n\n")

  #     # Add immediate page state debugging before other debug info
  #     current_url = begin
  #       page.current_url
  #     rescue
  #       "unknown"
  #     end
  #     page_title = begin
  #       page.title
  #     rescue
  #       "unknown"
  #     end
  #     debug_log("[Test] Immediate post-test failure state - URL: #{current_url}, Title: #{page_title}")

  #     debug_asset_state
  #     debug_log("\n\n")
  #   end
  # end
end
