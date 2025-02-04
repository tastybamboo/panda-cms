require "system_helper"

RSpec.describe "Website" do
  include_context "with standard pages"
  it "shows the homepage with rich text blocks and rendered JS" do
    visit "/"

    # Debug output for troubleshooting
    puts_debug "Current URL: #{page.current_url}"
    puts_debug "Page Title: #{page.title}"
    puts_debug "Page HTML:"
    puts_debug page.html

    # Wait for the layout to be visible
    expect(page).to have_content("Homepage Layout", wait: 1)

    # Wait for JavaScript to initialize
    expect(page).to have_content("I like ice cream!", wait: 1)
    expect(page).to have_content("Hello, Stimulus!", wait: 1)
  end

  it "shows the about page with plain text, code and rich text blocks" do
    visit "/about"

    # Debug output for troubleshooting
    about = Panda::CMS::Page.find_by(path: "/about")
    puts_debug "Page: #{about.attributes.inspect}"
    puts_debug "Block Contents:"
    about.block_contents.each do |bc|
      puts_debug "Block: #{bc.block.name}"
      puts_debug "Raw Content: #{bc.content.inspect}"
      puts_debug "Rendered Content: #{bc.cached_content.inspect}"
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
