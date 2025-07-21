# frozen_string_literal: true

module CupriteHelpers
  def pause
    page.driver.debug(binding)
  end

  def debug_page_state
    return unless ENV["DEBUG"]

    # Log any JS console errors
    if page.driver.browser.respond_to?(:manage)
      console_logs = page.driver.browser.manage.logs.get(:browser)
      if console_logs.present?
        console_logs.each { |log| }
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
