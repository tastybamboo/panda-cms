# frozen_string_literal: true

require "system_helper"

RSpec.describe "List pages", type: :system do
  before(:each) do
    login_as_admin
    visit "/admin/cms/pages"
  end

  it "shows the correct header" do
    # Use string-based checks to avoid DOM node issues
    html_content = page.html
    expect(html_content).to include("Pages")
    expect(html_content).to include('href="/admin/cms/pages/new"')
    expect(html_content).to include("Add Page")
  end

  it "does not render visible closing div tags in the table cells" do
    # Regression test for double-rendering bug where ERB block return values
    # were being output in addition to the block's buffer output
    page.html

    # The rendered content should not contain visible </div> text outside of HTML tags
    # We look for </div> appearing as visible text content
    expect(page).not_to have_text("</div>")
  end

  context "when there are nested pages" do
    # Note: The tree starts collapsed, so nested pages have display:none.
    # We check the HTML content directly to verify proper indentation classes.

    it "properly indents level 1 pages with ml-6" do
      html_content = page.html
      # Level 1 pages should have data-level="1" and ml-6 class
      expect(html_content).to include('data-level="1"')
      # About page should have ml-6 indentation
      expect(html_content).to match(/data-level="1"[^>]*>.*?ml-6/m)
    end

    it "properly indents level 2 pages with ml-12" do
      html_content = page.html
      # Level 2 pages should have data-level="2" and ml-12 class
      expect(html_content).to include('data-level="2"')
      expect(html_content).to match(/data-level="2"[^>]*>.*?ml-12/m)
    end

    it "properly indents level 3 pages with ml-[4.5rem]" do
      html_content = page.html
      # Level 3 pages should use arbitrary value syntax ml-[4.5rem]
      expect(html_content).to include('data-level="3"')
      expect(html_content).to match(/data-level="3"[^>]*>.*?ml-\[4\.5rem\]/m)
    end

    it "properly indents level 4+ pages with ml-24" do
      html_content = page.html
      # Level 4+ pages should have ml-24 class
      expect(html_content).to include('data-level="4"')
      expect(html_content).to match(/data-level="4"[^>]*>.*?ml-24/m)
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

  # context "when there are different page statuses" do
  #   it "shows an active page"

  #   it "shows a hidden page"

  #   it "shows a draft page"

  #   it "shows an archived page"
  # end
end
