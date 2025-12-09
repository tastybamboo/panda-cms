#!/usr/bin/env ruby
# minimal_cuprite_combined.rb
# Unified Cuprite diagnostic: navigation + DOM + screenshot + CDP events.

require "capybara/cuprite"
require "tmpdir"
require "fileutils"

puts "=== Cuprite Combined Smoke Test (Navigation + CDP Events) ==="

PROFILE_DIR = Dir.mktmpdir("cuprite-profile")
puts "[DEBUG] PROFILE_DIR = #{PROFILE_DIR}"

HTML = <<~HTML
  <!DOCTYPE html>
  <html>
  <body>
    <h1 id="msg">Hello from Cuprite</h1>
    <script>
      console.log("Console says hello");
      window.testValue = 123;
    </script>
  </body>
  </html>
HTML

html_path = File.join(PROFILE_DIR, "test.html")
File.write(html_path, HTML)
file_url = "file://#{html_path}"

puts "[STEP] Wrote HTML → #{html_path}"

begin
  puts "[STEP] Launching Cuprite::Browser…"

  browser = Capybara::Cuprite::Browser.new(
    headless: true,
    timeout: 10,
    process_timeout: 10,
    browser_path: "/usr/bin/google-chrome",
    browser_options: {
      "no-sandbox" => nil,
      "disable-gpu" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-background-networking" => nil,
      "disable-software-rasterizer" => nil,
      "disable-features" => "UseOzonePlatform",
      "user-data-dir" => PROFILE_DIR
    }
  )

  puts "[STEP] Browser launched OK."

  page = browser.create_page
  puts "[STEP] Created page object."

  # Attach CDP event listeners
  client = page.client

  client.on("Page.domContentEventFired") do
    puts "[CDP] ⚡ domContentEventFired"
  end

  client.on("Page.loadEventFired") do
    puts "[CDP] 📄 loadEventFired"
  end

  client.on("Runtime.consoleAPICalled") do |event|
    text = begin
      event["args"][0]["value"]
    rescue
      "?"
    end
    puts "[CDP] 📣 console.log → #{text}"
  end

  puts "[STEP] Enabling CDP Page + Runtime events…"
  client.command("Page.enable")
  client.command("Runtime.enable")

  puts "[STEP] Navigating to #{file_url.inspect}…"
  page.goto(file_url)

  text = page.evaluate("document.querySelector('#msg').textContent")
  puts "[RESULT] DOM text = #{text.inspect}"

  val = page.evaluate("window.testValue")
  puts "[RESULT] JS window.testValue = #{val.inspect}"

  screenshot_path = File.join(PROFILE_DIR, "combined_screenshot.png")
  page.screenshot(path: screenshot_path)
  puts "[RESULT] Screenshot saved → #{screenshot_path}"

  browser.quit
  puts "[DONE] Combined Cuprite test completed successfully."
rescue => e
  warn "\n[ERROR] #{e.class}: #{e.message}"
  warn e.backtrace.join("\n")
ensure
  puts "\n=== DevToolsActivePort ==="
  port_file = File.join(PROFILE_DIR, "DevToolsActivePort")
  puts(File.exist?(port_file) ? File.read(port_file) : "(not found)")

  puts "\nProfile directory preserved at:"
  puts PROFILE_DIR
end
