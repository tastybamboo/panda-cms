# frozen_string_literal: true

# Helper methods for Panda CMS system tests
module PandaCmsHelpers
  # Debug logging helper - only outputs when RSPEC_DEBUG=true
  def debug_log(message)
    puts message if ENV["RSPEC_DEBUG"] == "true"
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
end

RSpec.configure do |config|
  config.include PandaCmsHelpers, type: :system
end
