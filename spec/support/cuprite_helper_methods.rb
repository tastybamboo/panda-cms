module CupriteHelpers
  def pause
    page.driver.debug(binding)
  end

  def debug_page_state
    return unless ENV["DEBUG"]
    puts_debug "Current Path: #{page.current_path}"
    puts_debug "Page Title: #{page.title}"

    # Log any JS console errors
    if page.driver.browser.respond_to?(:manage)
      console_logs = page.driver.browser.manage.logs.get(:browser)
      if console_logs.present?
        puts_debug "Browser Console Logs:"
        console_logs.each { |log| puts_debug "  #{log.message}" }
      end
    end
  rescue => e
    puts_debug "Error capturing page state: #{e.message}"
  end

  def click_css(selector)
    puts_debug "Clicking CSS selector: #{selector}"
    find(selector).click
  end

  def click_text(text)
    puts_debug "Clicking text: #{text}"
    find(:xpath, "//*[contains(text(), '#{text}')]").click
  end

  def click_button_text(text)
    puts_debug "Clicking button with text: #{text}"
    find(:xpath, "//button[contains(text(), '#{text}')]").click
  end

  def click_link_text(text)
    puts_debug "Clicking link with text: #{text}"
    find(:xpath, "//a[contains(text(), '#{text}')]").click
  end
end
