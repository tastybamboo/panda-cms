# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug Network Requests", type: :system do
  fixtures :all

  before do
    login_as_admin
  end

  it "checks if CMS JavaScript files are being served correctly" do
    driven_by(:cuprite)

    # Subscribe to network events before visiting page
    requests = []
    responses = []

    page.driver.browser.on(:request) do |request|
      requests << {url: request.url, method: request.method}
    end

    page.driver.browser.on(:response) do |response|
      responses << {
        url: response.url,
        status: response.status,
        headers: response.headers
      }
    end

    visit edit_admin_cms_page_path(panda_cms_pages(:about_page))

    # Wait for page to settle and assets to load
    sleep 3

    puts "\n" + "=" * 80
    puts "NETWORK TRAFFIC ANALYSIS"
    puts "=" * 80
    puts "Total Requests: #{requests.count}"
    puts "Total Responses: #{responses.count}"

    # Find all JavaScript module requests
    js_requests = requests.select { |req| req[:url].include?(".js") }
    js_responses = responses.select { |res| res[:url].include?(".js") }

    puts "\nJavaScript Requests (#{js_requests.count} total):"
    js_requests.each do |req|
      url = req[:url]
      matching_response = js_responses.find { |res| res[:url] == url }

      puts "\n  URL: #{url}"
      puts "  Method: #{req[:method]}"

      if matching_response
        status = matching_response[:status]
        content_type = matching_response[:headers]["Content-Type"] || matching_response[:headers]["content-type"]

        puts "  Status: #{status}"
        puts "  Content-Type: #{content_type}"

        if url.include?("/panda/")
          puts "  ⭐ PANDA MODULE"
          if status != 200
            puts "  ❌ FAILED REQUEST"
          else
            puts "  ✅ SUCCESS"
          end
        end
      else
        puts "  Status: NO RESPONSE RECEIVED"
        puts "  ❌ NO RESPONSE"
      end
    end

    # Specifically check for our critical modules
    critical_modules = [
      "/panda/cms/application.js",
      "/panda/cms/controllers/index.js",
      "/panda/core/application.js",
      "/panda/core/controllers/index.js"
    ]

    puts "\n" + "-" * 80
    puts "CRITICAL MODULE STATUS:"
    puts "-" * 80

    critical_modules.each do |module_path|
      matching_requests = requests.select { |req| req[:url].include?(module_path) }

      if matching_requests.empty?
        puts "\n  #{module_path}"
        puts "  ❌ NEVER REQUESTED"
      else
        matching_requests.each do |req|
          matching_response = responses.find { |res| res[:url] == req[:url] }
          status = matching_response&.dig(:status)

          puts "\n  #{module_path}"
          puts "  Status: #{status || "NO RESPONSE"}"
          puts "  #{(status == 200) ? "✅" : "❌"} #{(status == 200) ? "LOADED" : "FAILED"}"
        end
      end
    end

    puts "\n" + "=" * 80
  end
end
