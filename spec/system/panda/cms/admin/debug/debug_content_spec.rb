# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug File Content", type: :system do
  fixtures :all

  before do
    login_as_admin
  end

  it "checks what content is actually being served" do
    driven_by(:cuprite)

    visit edit_admin_cms_page_path(panda_cms_pages(:about_page))
    sleep 1

    # Get the base URL
    current_url = URI.parse(page.current_url)
    base_url = "#{current_url.scheme}://#{current_url.host}:#{current_url.port}"

    puts "\n" + "=" * 80
    puts "CHECKING FILE CONTENT"
    puts "=" * 80

    # Navigate to the CMS application.js file
    visit "#{base_url}/panda/cms/application.js"
    sleep 0.5

    content = page.html

    puts "\nCMS Application.js Response:"
    puts "Status: #{page.status_code}"
    puts "Content-Type: #{page.response_headers["Content-Type"]}"
    puts "Content length: #{content.length}"
    puts "\nFirst 500 characters:"
    puts content[0..500]

    if content.include?("<pre")
      puts "\n❌ WRAPPED IN HTML"
    elsif content.include?("import")
      puts "\n✅ RAW JAVASCRIPT"
    end

    # Try Core as well
    visit "#{base_url}/panda/core/application.js"
    sleep 0.5

    content = page.html

    puts "\n" + "-" * 80
    puts "\nCore Application.js Response:"
    puts "Status: #{page.status_code}"
    puts "Content-Type: #{page.response_headers["Content-Type"]}"
    puts "Content length: #{content.length}"
    puts "\nFirst 500 characters:"
    puts content[0..500]

    if content.include?("<pre")
      puts "\n❌ WRAPPED IN HTML"
    elsif content.include?("import")
      puts "\n✅ RAW JAVASCRIPT"
    elsif content.include?("404")
      puts "\n❌ 404 ERROR"
    end

    puts "\n" + "=" * 80
  end
end
