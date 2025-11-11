# frozen_string_literal: true

require "system_helper"

RSpec.describe "Debug about:blank navigation", type: :system do
  fixtures :all

  let(:about_page) { panda_cms_pages(:about_page) }

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  it "debugs the visit to edit page" do
    puts "\n=== Before visit ==="
    puts "Current URL: #{page.current_url}"
    puts "About page ID: #{about_page.id}"
    puts "About page path: #{about_page.path}"

    visit "/admin/cms/pages/#{about_page.id}/edit"

    puts "\n=== After visit ==="
    puts "Current URL: #{page.current_url}"
    puts "Page title: #{page.title}"
    puts "Page HTML length: #{page.html.length}"

    puts "\n=== Checking for About content ==="
    has_about = page.has_content?("About", wait: 2)
    puts "Has 'About' content: #{has_about}"
    puts "Current URL after content check: #{page.current_url}"

    puts "\n=== Opening slideover ==="
    page.execute_script("
      var slideover = document.querySelector('#slideover');
      if (slideover) {
        slideover.classList.remove('hidden');
      }
    ")

    puts "Current URL after execute_script: #{page.current_url}"
    puts "Page title after script: #{page.title}"

    puts "\n=== Checking for slideover ==="
    has_slideover = page.has_css?("#slideover", visible: true, wait: 2)
    puts "Has visible slideover: #{has_slideover}"
    puts "Current URL after slideover check: #{page.current_url}"

    expect(true).to be true
  end
end
