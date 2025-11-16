# frozen_string_literal: true

require "system_helper"

RSpec.describe "Page Load Test", :debug, :aggregate_failures, type: :system do
  # This test runs early (aaa_ prefix) to test if Chrome can load actual pages
  # If this passes, Chrome is fine and the issue is specific to certain pages/features
  # If this fails, the issue is with page loading or JavaScript/assets in general

  it "can visit the root page without crashing" do
    visit "/"
    expect(page.status_code).to eq(200)
  end

  it "tunes sandbox" do
    Capybara.register_driver(:cuprite) do |app|
      Capybara::Cuprite::Driver.new(app, browser_options: {"no-sandbox": nil}, window_size: [1200, 800])
    end
    Capybara.javascript_driver = :cuprite

    visit "/"
    expect(page.status_code).to eq(200)
  end
end
