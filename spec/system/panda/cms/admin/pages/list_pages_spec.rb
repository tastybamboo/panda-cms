# frozen_string_literal: true

require "system_helper"

RSpec.describe "List pages", type: :system do
  before(:each) do
    login_as_admin
    visit "/admin/pages"
  end

  it "shows the correct header" do
    # Use string-based checks to avoid DOM node issues
    html_content = page.html
    expect(html_content).to include("Pages")
    expect(html_content).to include('href="/admin/pages/new"')
    expect(html_content).to include("Add Page")
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
