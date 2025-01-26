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
    page.driver.browser.network.wait_for_idle(timeout: timeout)
    true
  rescue Ferrum::TimeoutError
    false
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
    page.driver.pause
  end

  # Drop #browser_debug anywhere in a test to open a Chrome inspector and pause the execution
  # Usage: browser_debug(binding)
  def browser_debug(*)
    page.driver.debug(*)
  end

  # Allows sending a list of CSS selectors to be clicked on in the correct order (no delay)
  # Useful where you need to trigger e.g. a blur event on an input field
  def click_on_selectors(*css_selectors)
    css_selectors.each do |selector|
      page.driver.browser.at_css(selector).click
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

  # Trigger slug generation and wait for the result
  def trigger_slug_generation(title)
    # First clear any existing value
    find("input#page_title").set("")

    # Type the title character by character to simulate real typing
    title.each_char do |char|
      find("input#page_title").send_keys(char)
      sleep 0.05 # Small delay between characters
    end

    # Now trigger the blur event
    find("input#page_title").send_keys(:tab)

    # Get parent path if one is selected
    parent_path = ""
    if page.has_select?("Parent") && page.has_select?("Parent", selected: /.+/)
      parent_text = page.find("select#page_parent_id option[selected]").text
      if parent_text =~ /.*\((.*)\)$/
        parent_path = $1.sub(/\/$/, "") # Remove trailing slash if present
      end
    end

    # Wait for the expected URL to appear
    slug = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
    expected_url = parent_path.empty? ? "/#{slug}" : "#{parent_path}/#{slug}"

    # Add debug output
    puts_debug "Waiting for URL field to have value: #{expected_url}"

    # Wait longer for the value to appear
    wait_for_field_value("URL", expected_url, timeout: 10)
  end
end
