#!/usr/bin/env ruby
# minimal_ferrum.rb
require "ferrum"
require "tmpdir"

# Create an isolated, unique profile directory
PROFILE_DIR = Dir.mktmpdir("ferrum-profile")
puts "[DEBUG] PROFILE_DIR = #{PROFILE_DIR}"

begin
  puts "[STEP] Launching Ferrum::Browser…"

  browser = Ferrum::Browser.new(
    headless: true,
    timeout: 15,
    process_timeout: 20,
    browser_path: "/usr/bin/google-chrome",
    browser_options: {
      "no-sandbox" => nil,
      "disable-gpu" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-background-networking" => nil,
      "disable-software-rasterizer" => nil,
      "disable-features" => "UseOzonePlatform",
      "remote-debugging-port" => 0,
      "user-data-dir" => PROFILE_DIR
    }
  )

  puts "[STEP] Browser launched."
  puts "[STEP] Evaluating JS: 1 + 1…"

  result = browser.evaluate("1 + 1")
  puts "[RESULT] JS result = #{result.inspect}"

  puts "[STEP] Fetching browser version…"
  version = browser.command("Browser.getVersion")
  puts "[RESULT] Browser version: #{version.inspect}"

  # ---------------------------------------------------------------------------
  # CONTINUATION: Create a page, navigate, evaluate JS, take screenshot, exercise CDP
  # ---------------------------------------------------------------------------
  puts ""
  puts "[CONTINUATION]"
  puts ""

  puts "[STEP] Creating new page…"
  page = browser.create_page
  puts "[STEP] Page created (id: #{page.object_id})"

  test_url = "data:text/html,<h1>Hello from Ferrum</h1><script>console.log('Hello console');</script>"
  puts "[STEP] Navigating to #{test_url.inspect}…"
  page.goto(test_url)

  puts "[STEP] Page loaded. Evaluating DOM…"
  h1_text = page.evaluate("document.querySelector('h1').textContent")
  puts "[RESULT] h1 text = #{h1_text.inspect}"

  puts "[STEP] Listening for console events…"
  page.on("console") do |msg|
    puts "[CONSOLE] #{msg.text}"
  end

  # Force a console message
  page.evaluate("console.log('Console inside evaluation');")

  # Try an explicit CDP command on the page
  puts "[STEP] Fetching layout metrics (CDP)…"
  layout = page.command("Page.getLayoutMetrics")
  puts "[RESULT] Layout metrics: #{layout.inspect}"

  # Screenshot
  screenshot_path = File.join(PROFILE_DIR, "screenshot.png")
  puts "[STEP] Taking screenshot → #{screenshot_path}"
  page.screenshot(path: screenshot_path)
  puts "[RESULT] Screenshot saved."

  # Cleanup page
  puts "[STEP] Closing page…"
  page.close

  # Close browser (you already have browser.quit, this is just narrative accuracy)
  puts "[STEP] Closing browser…"
  browser.quit

  puts "[DONE] Ferrum extended test completed successfully."
rescue => e
  warn "[ERROR] #{e.class}: #{e.message}"
  warn e.backtrace.join("\n")
ensure
  puts "[CLEANUP] Listing profile directory:"
  system("ls -al #{PROFILE_DIR}")

  devtools_file = File.join(PROFILE_DIR, "DevToolsActivePort")
  if File.exist?(devtools_file)
    puts "[DEBUG] DevToolsActivePort content:"
    puts File.read(devtools_file)
  else
    puts "[DEBUG] DevToolsActivePort NOT FOUND."
  end
end
