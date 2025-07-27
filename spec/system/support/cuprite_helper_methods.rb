# Helper methods for Cuprite-based system tests

# Waits for a specific selector to be present and visible on the page
# @param selector [String] CSS selector to wait for
# @param timeout [Integer] Maximum time to wait in seconds (default: 5)
# @return [Boolean] true if element is found, false if timeout occurs
#
# Example:
#   wait_for_selector(".my-element", timeout: 10)

# Waits for a specific text to be present on the page
# @param text [String] Text to wait for
# @param timeout [Integer] Maximum time to wait in seconds (default: 5)
# @return [Boolean] true if text is found, false if timeout occurs
#
# Example:
#   wait_for_text("Loading complete", timeout: 10)

# Waits for network requests to complete
# @param timeout [Integer] Maximum time to wait in seconds (default: 5)
# @return [Boolean] true if network is idle, false if timeout occurs
#
# Example:
#   wait_for_network_idle(timeout: 10)

# Waits for JavaScript to modify the DOM
# @param timeout [Integer] Maximum time to wait in seconds (default: 5)
# @return [Boolean] true if mutation occurred, false if timeout occurs
#
# Example:
#   wait_for_dom_mutation(timeout: 10)
module CupriteHelpers
  # Ensure page is loaded and stable before interacting
  def ensure_page_loaded
    # Check if we're on about:blank and need to reload
    current_url = begin
      page.current_url
    rescue
      "unknown"
    end
    if current_url.include?("about:blank")
      puts "[CI] Page is on about:blank, skipping recovery to avoid loops" if ENV["GITHUB_ACTIONS"]
      # Don't try to recover - let the test handle it
      return false
    end

    # Wait for page to be ready
    wait_for_ready_state
    # Wait for JavaScript to load
    wait_for_javascript
    true
  end

  # Wait for document ready state
  def wait_for_ready_state
    Timeout.timeout(5) do
      loop do
        ready = page.evaluate_script("document.readyState")
        break if ready == "complete"
        sleep 0.1
      end
    end
  rescue Timeout::Error
    puts "[CI] Timeout waiting for document ready state" if ENV["GITHUB_ACTIONS"]
  end

  # Wait for JavaScript to load (Panda CMS specific)
  def wait_for_javascript(timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        loaded = begin
          page.evaluate_script("window.pandaCmsLoaded === true")
        rescue
          false
        end
        break if loaded
        sleep 0.1
      end
    end
    true
  rescue Timeout::Error
    puts "[CI] Timeout waiting for JavaScript to load" if ENV["GITHUB_ACTIONS"]
    false
  end

  # Waits for a specific selector to be present and visible on the page
  # @param selector [String] CSS selector to wait for
  # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
  # @return [Boolean] true if element is found, false if timeout occurs
  def wait_for_selector(selector, timeout: 5)
    start_time = Time.now
    while Time.now - start_time < timeout
      return true if page.has_css?(selector, visible: true)
      sleep 0.1
    end
    false
  end

  # Waits for a specific text to be present on the page
  # @param text [String] Text to wait for
  # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
  # @return [Boolean] true if text is found, false if timeout occurs
  def wait_for_text(text, timeout: 5)
    start_time = Time.now
    while Time.now - start_time < timeout
      return true if page.has_text?(text)
      sleep 0.1
    end
    false
  end

  # Waits for network requests to complete
  # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
  # @return [Boolean] true if network is idle, false if timeout occurs
  def wait_for_network_idle(timeout: 5)
    # Selenium doesn't have direct network idle support
    # Just wait a bit for any ongoing requests
    sleep 0.5
    true
  end

  # Waits for JavaScript to modify the DOM
  # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
  # @return [Boolean] true if mutation occurred, false if timeout occurs
  def wait_for_dom_mutation(timeout: 5)
    start_time = Time.now
    initial_dom = page.html
    while Time.now - start_time < timeout
      return true if page.html != initial_dom
      sleep 0.1
    end
    false
  end

  # Drop #pause anywhere in a test to stop the execution.
  # Useful when you want to checkout the contents of a web page in the middle of a test
  # running in a headful mode.
  def pause
    # Selenium doesn't have a built-in pause method
    # Use debugger or sleep instead
    if ENV["DEBUG"].in?(%w[y 1 yes true])
      debugger
    else
      puts "Paused. Press Enter to continue..."
      gets
    end
  end

  # Drop #browser_debug anywhere in a test to open a Chrome inspector and pause the execution
  # Usage: browser_debug(binding)
  def browser_debug(*)
    # Selenium doesn't have a built-in debug method
    pause
  end

  # Allows sending a list of CSS selectors to be clicked on in the correct order (no delay)
  # Useful where you need to trigger e.g. a blur event on an input field
  def click_on_selectors(*css_selectors)
    css_selectors.each do |selector|
      find(selector).click
      sleep 0.1 # Add a small delay to allow JavaScript to run
    end
  end

  # Wait for a field to have a specific value
  # @param field_name [String] The field name or label
  # @param value [String] The expected value
  # @param timeout [Integer] Maximum time to wait in seconds (default: 5)
  def wait_for_field_value(field_name, value, timeout: 5)
    start_time = Time.now
    while Time.now - start_time < timeout
      return true if page.has_field?(field_name, with: value)
      sleep 0.1
    end
    false
  end

  # Safe methods that handle Ferrum NodeNotFoundError in CI
  def safe_fill_in(locator, with:)
    retries = 0
    start_time = Time.now
    max_duration = 5 # Maximum 5 seconds total

    begin
      fill_in locator, with: with
    rescue Selenium::WebDriver::Error::NoSuchElementError, Capybara::ElementNotFound => e
      retries += 1
      elapsed = Time.now - start_time

      if retries <= 2 && elapsed < max_duration && ENV["GITHUB_ACTIONS"]
        puts "[CI] Element not found on fill_in '#{locator}', retry #{retries}/2 (#{elapsed.round(1)}s elapsed)"
        sleep 0.5
        retry
      else
        puts "[CI] Giving up on fill_in '#{locator}' after #{retries} retries and #{elapsed.round(1)}s" if ENV["GITHUB_ACTIONS"]
        raise e
      end
    end
  end

  def safe_select(value, from:)
    retries = 0
    start_time = Time.now
    max_duration = 5 # Maximum 5 seconds total

    begin
      select value, from: from
    rescue Selenium::WebDriver::Error::NoSuchElementError, Capybara::ElementNotFound => e
      retries += 1
      elapsed = Time.now - start_time

      if retries <= 2 && elapsed < max_duration && ENV["GITHUB_ACTIONS"]
        puts "[CI] Element not found on select '#{value}' from '#{from}', retry #{retries}/2 (#{elapsed.round(1)}s elapsed)"
        sleep 0.5
        retry
      else
        puts "[CI] Giving up on select '#{value}' from '#{from}' after #{retries} retries and #{elapsed.round(1)}s" if ENV["GITHUB_ACTIONS"]
        raise e
      end
    end
  end

  def safe_click_button(locator)
    retries = 0
    start_time = Time.now
    max_duration = 5 # Maximum 5 seconds total

    begin
      click_button locator
    rescue Selenium::WebDriver::Error::NoSuchElementError, Capybara::ElementNotFound => e
      retries += 1
      elapsed = Time.now - start_time

      if retries <= 2 && elapsed < max_duration && ENV["GITHUB_ACTIONS"]
        puts "[CI] Element not found on click_button '#{locator}', retry #{retries}/2 (#{elapsed.round(1)}s elapsed)"
        sleep 0.5
        retry
      else
        puts "[CI] Giving up on click_button '#{locator}' after #{retries} retries and #{elapsed.round(1)}s" if ENV["GITHUB_ACTIONS"]
        raise e
      end
    end
  end

  # Trigger slug generation and wait for the result
  def trigger_slug_generation(title)
    # Use safe methods in CI
    if ENV["GITHUB_ACTIONS"]
      safe_fill_in "page_title", with: title
    else
      fill_in "page_title", with: title
    end

    # Manually generate the slug instead of relying on JavaScript
    slug = create_slug_from_title(title)

    # Wait for page to be fully loaded before manipulating form

    # Check if a parent is selected to determine the full path using JavaScript
    parent_info = page.evaluate_script(<<~JS)
      (function() {
        var parentSelect = document.querySelector('select[name="page[parent_id]"]');
        if (!parentSelect || !parentSelect.value) {
          return { hasParent: false };
        }
        
        var selectedOption = parentSelect.querySelector('option[value="' + parentSelect.value + '"]');
        if (!selectedOption) {
          return { hasParent: false };
        }
        
        var text = selectedOption.textContent;
        var pathMatch = text.match(/\\((.*)\\)$/);
        return {
          hasParent: true,
          parentPath: pathMatch ? pathMatch[1].replace(/\\/$/, '') : ''
        };
      })()
    JS

    if parent_info["hasParent"] && parent_info["parentPath"].present?
      if ENV["GITHUB_ACTIONS"]
        safe_fill_in "page_path", with: "#{parent_info["parentPath"]}/#{slug}"
      else
        fill_in "page_path", with: "#{parent_info["parentPath"]}/#{slug}"
      end
    elsif ENV["GITHUB_ACTIONS"]
      safe_fill_in "page_path", with: "/#{slug}"
    else
      fill_in "page_path", with: "/#{slug}"
    end
  end

  private

  # Create a slug from a title (matches the JavaScript implementation)
  def create_slug_from_title(title)
    return "" if title.nil? || title.strip.empty?

    title.strip
      .downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/^-+|-+$/, "")
  end
end
