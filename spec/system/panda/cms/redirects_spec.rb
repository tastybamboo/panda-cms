require "system_helper"

RSpec.describe "When following redirects", type: :system do
  include_context "with standard pages"

  let(:about_page) { Panda::CMS::Page.find_by(path: "/about") }
  let!(:redirect) do
    Panda::CMS::Redirect.create!(
      origin_panda_cms_page_id: nil,
      destination_panda_cms_page_id: nil,
      status_code: 301,
      visits: 0,
      origin_path: "/old-about",
      destination_path: "/about"
    )
  end

  it "redirects from old paths to new paths" do
    visit "/old-about"

    # Should be redirected to the new path
    expect(page).to have_current_path("/about")

    # Content should be visible
    expect(page).to have_content("About")

    # Redirect visit count should be incremented
    expect(redirect.reload.visits).to eq(1)
  end

  it "follows multiple redirects in sequence" do
    # Create a chain of redirects
    second_redirect = Panda::CMS::Redirect.create!(
      origin_panda_cms_page_id: nil,
      destination_panda_cms_page_id: nil,
      status_code: 301,
      visits: 0,
      origin_path: "/very-old-about",
      destination_path: "/old-about"
    )

    visit "/very-old-about"

    # Should be redirected through the chain to the final path
    expect(page).to have_current_path("/about")

    # Both redirects should have their visit counts incremented
    expect(second_redirect.reload.visits).to eq(1)
    expect(redirect.reload.visits).to eq(1)
  end

  it "handles redirects for pages that change paths" do
    # Change the page path which should create a redirect
    about_page.path = "/new-about"
    about_page.save!

    expect(about_page.reload.path).to eq("/new-about")

    new_redirect = Panda::CMS::Redirect.find_by(origin_path: "/about", destination_path: "/new-about")
    expect(new_redirect).to be_present

    # Visit the old path
    visit "/about"

    # Should be redirected to the new path
    expect(page).to have_current_path("/new-about")

    # Wait for the page to fully load after redirect
    expect(page).to have_content("About")

    # Wait a moment for the visit count to be updated
    sleep 0.5

    # The automatically created redirect should have a visit
    expect(new_redirect.reload.visits).to eq(1)
  end
end
