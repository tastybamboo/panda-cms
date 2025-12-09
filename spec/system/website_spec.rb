# frozen_string_literal: true

require "system_helper"

RSpec.describe "Website" do
  fixtures :all

  it "shows the homepage with JavaScript functionality", skip: "Chrome fails to start for this test in CI - timing/resource issue" do
    visit "/"

    # Test basic page content
    html_content = page.html
    expect(html_content.include?("Homepage Layout")).to be true

    # Test that JavaScript modules load and execute
    # Wait specifically for the vanilla JS to modify the DOM element
    expect(page).to have_content("I like ice cream!", wait: 5)
  end

  it "shows the about page with plain text, code and rich text blocks", :flaky do
    visit "/about"

    # Test what the user sees
    expect(page).to have_content("This is the main content of the about page")
    expect(page).to have_content("Here is some HTML code")
    expect(page).to have_content("Here is some plain text content")

    # Test that HTML is rendered correctly
    expect(page).to have_css("p strong", text: "Here is some HTML code")
    expect(page).to have_css("p", text: "This is the main content of the about page")
  end
end
