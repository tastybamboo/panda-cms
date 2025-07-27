# frozen_string_literal: true

module CupriteHelpers
  def pause
    # Selenium doesn't have a built-in debug method
    if ENV["DEBUG"].in?(%w[y 1 yes true])
      debugger
    else
      puts "Paused. Press Enter to continue..."
      gets
    end
  end

  def debug_page_state
    return unless ENV["DEBUG"]

    # Log any JS console errors
    if page.driver.browser.respond_to?(:logs)
      console_logs = page.driver.browser.logs.get(:browser)
      if console_logs.present?
        console_logs.each { |log| puts "[Console] #{log.level}: #{log.message}" }
      end
    end
  rescue
  end

  def click_css(selector)
    find(selector).click
  end

  def click_text(text)
    find(:xpath, "//*[contains(text(), '#{text}')]").click
  end

  def click_button_text(text)
    find(:xpath, "//button[contains(text(), '#{text}')]").click
  end

  def click_link_text(text)
    find(:xpath, "//a[contains(text(), '#{text}')]").click
  end
end
