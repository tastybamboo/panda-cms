# frozen_string_literal: true

require "system_helper"

RSpec.describe "Server Verification", type: :system do
  it "verifies that Capybara server starts" do
    puts "\n[Server Debug] Capybara server: #{Capybara.server}"
    puts "[Server Debug] Capybara server_host: #{Capybara.server_host}"
    puts "[Server Debug] Capybara server_port: #{Capybara.server_port}"
    puts "[Server Debug] Capybara app_host: #{Capybara.app_host}"
    puts "[Server Debug] Capybara default_driver: #{Capybara.default_driver}"
    puts "[Server Debug] Capybara javascript_driver: #{Capybara.javascript_driver}"
    puts "[Server Debug] Capybara current_driver: #{Capybara.current_driver}"

    # This should trigger Capybara to boot the server
    visit "/"

    # Get the server URL
    server_url = Capybara.current_session.server_url rescue "unknown"
    puts "[Server Debug] Server URL: #{server_url}"

    # Check if we can actually access it
    expect(page.status_code).to be_between(200, 404).or be_nil

    puts "✅ Server verification PASSED - Capybara server is running"
  end
end
