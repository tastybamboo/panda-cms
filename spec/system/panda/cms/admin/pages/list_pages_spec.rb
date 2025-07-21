# frozen_string_literal: true

require "system_helper"

RSpec.describe "List pages", type: :system do
  fixtures :all

  before(:each) do
    # Reset session more thoroughly for CI stability
    if ENV["CI"]
      Capybara.reset_sessions!
      sleep(1)
    end

    # Retry mechanism for CI navigation issues
    retries = ENV["CI"] ? 3 : 1
    success = false

    retries.times do |attempt|
      begin
        if ENV["CI"] && attempt > 0
          puts "[CI Retry] Attempt #{attempt + 1} for list pages navigation"
          Capybara.reset_sessions!
          sleep(2)
        end

        login_as_admin

        if ENV["CI"]
          puts "[CI Debug] About to visit /admin/pages (attempt #{attempt + 1})"
          puts "[CI Debug] Current URL before visit: #{page.current_url}"
        end

        visit "/admin/pages"

        if ENV["CI"]
          puts "[CI Debug] After visiting list pages"
          puts "[CI Debug] Current URL: #{page.current_url}"
          puts "[CI Debug] Page HTML length: #{page.html.length}"
        end

        # Basic check to ensure page loaded
        expect(page).to have_current_path("/admin/pages", wait: 10)

        success = true
        break

      rescue => e
        if ENV["CI"]
          puts "[CI Debug] List pages attempt #{attempt + 1} failed: #{e.message}"
          puts "[CI Debug] Current URL: #{page.current_url}"
          if page.html.length < 100
            puts "[CI Debug] Page content: #{page.html}"
          end

          if attempt < retries - 1
            puts "[CI Debug] Will retry list pages navigation..."
            next
          else
            puts "[CI Debug] All list pages attempts failed, giving up"
            raise
          end
        else
          raise
        end
      end
    end
  end

  it "shows the correct header" do
    within "h1" do
      expect(page).to have_content("Pages")
      expect(page).to have_link("Add Page", href: "/admin/pages/new")
    end
  end

  # it "shows a list of pages with name and path"

  # it "shows when a page was last updated"

  # it "shows who last updated a page"

  # context "when there are no pages" do
  #   # This is an error condition, as it means the homepage has
  #   # been deleted or the seeds have not been run
  #   it "shows a message that there are no pages"
  # end

  # context "when there is a homepage" do
  # end

  # context "when there are subpages" do
  #   it "properly indents subpages"

  #   it "shows the correct paths"
  # end

  # context "when there are different page statuses" do
  #   it "shows an active page"

  #   it "shows a hidden page"

  #   it "shows a draft page"

  #   it "shows an archived page"
  # end
end
