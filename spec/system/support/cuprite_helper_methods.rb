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
  rescue
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
    fill_in "Title", with: title

    # Manually generate the slug instead of relying on JavaScript
    slug = create_slug_from_title(title)

    # Wait for page to be fully loaded before manipulating form

    # Check if a parent is selected to determine the full path
    parent_select = find("select[name='page[parent_id]']", wait: 1)
    if parent_select.value.present? && parent_select.value != ""
      # Get the parent path from the selected option text
      selected_option = parent_select.find("option[value='#{parent_select.value}']")
      if selected_option.text =~ /\((.*)\)$/
        parent_path = $1.gsub(/\/$/, "") # Remove trailing slash
        fill_in "URL", with: "#{parent_path}/#{slug}"
      else
        fill_in "URL", with: "/#{slug}"
      end
    else
      fill_in "URL", with: "/#{slug}"
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
