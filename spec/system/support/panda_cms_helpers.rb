# frozen_string_literal: true

# Helper methods for Panda CMS system tests
module PandaCmsHelpers
  # Debug logging helper - only outputs when RSPEC_DEBUG=true
  def debug_log(message)
    puts message if ENV["RSPEC_DEBUG"] == "true"
  end

  # OPTIMIZED LOGIN - Reuses session across tests to avoid redundant logins
  # This caches the admin session and only logs in once per test file
  #
  # Usage in RSpec:
  #   before(:all) { ensure_admin_logged_in }
  #   after(:all) { reset_admin_session }
  #
  # Note: For comprehensive OAuth flow testing,
  # see spec/system/panda/core/admin/authentication_spec.rb in panda-core
  def ensure_admin_logged_in
    return @logged_in_admin if @logged_in_admin && session_still_valid?

    @logged_in_admin = login_as_admin
    debug_log("[OptimizedLogin] Logged in as admin (will reuse session)")
    @logged_in_admin
  end

  def reset_admin_session
    @logged_in_admin = nil
    Capybara.reset_sessions!
    debug_log("[OptimizedLogin] Reset admin session")
  end

  # Check if the current session is still valid (user is logged in)
  def session_still_valid?
    return false unless @logged_in_admin
    return false unless respond_to?(:page)

    begin
      # Quick check: are we on an admin page?
      current_url = begin
        page.current_url
      rescue
        nil
      end
      return false if current_url.nil? || current_url.include?("about:blank")

      # If we can access an admin page, session is valid
      return true if current_url.include?("/admin/cms")

      false
    rescue
      false
    end
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
          sleep 0.1
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
          sleep 0.1
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

      sleep 0.1
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
end

RSpec.configure do |config|
  config.include PandaCmsHelpers, type: :system
end
