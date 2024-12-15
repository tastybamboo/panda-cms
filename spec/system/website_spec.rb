require "system_helper"

RSpec.describe "Website" do
  include_context "with standard pages"
  it "shows the homepage with rich text blocks and rendered JS" do
    visit "/"

    # Debug output for troubleshooting
    if ENV["DEBUG"]
      debug "Current URL: #{page.current_url}"
      debug "Page Title: #{page.title}"
      debug "Page HTML:"
      debug page.html
    end

    # Wait for the layout to be visible
    expect(page).to have_content("Homepage Layout", wait: 10)

    # Wait for JavaScript to initialize
    expect(page).to have_content("I like ice cream!", wait: 10)
    expect(page).to have_content("Hello, Stimulus!", wait: 10)
  end

  it "shows the about page with plain text, code and rich text blocks" do
    visit "/about"

    # Debug output for troubleshooting
    if ENV["DEBUG"]
      about = Panda::CMS::Page.find_by(path: "/about")
      debug "Page: #{about.attributes.inspect}"
      debug "Block Contents:"
      about.block_contents.each do |bc|
        debug "Block: #{bc.block.name}"
        debug "Raw Content: #{bc.content.inspect}"
        debug "Rendered Content: #{bc.cached_content.inspect}"
      end
    end

    # Test what the user sees
    expect(page).to have_content("This is the main content of the about page")
    expect(page).to have_content("Here is some HTML code")
    expect(page).to have_content("Here is some plain text content")

    # Test that HTML is rendered correctly
    expect(page).to have_css("p strong", text: "Here is some HTML code")
    expect(page).to have_css("p", text: "This is the main content of the about page")
  end
end
