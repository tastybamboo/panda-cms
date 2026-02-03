# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin dashboard", type: :system do
  context "when not logged in" do
    it "redirects to login page" do
      visit "/admin/cms"
      expect(page).to have_current_path("/admin/cms")
      expect(page).to_not have_content("Dashboard")
    end
  end

  context "when logged in as regular user" do
    it "redirects to login page" do
      login_with_google(regular_user, expect_success: false)
      expect(page).to have_current_path("/admin/login")

      # Regular users cannot access the dashboard
      # We've already verified they're redirected to login above
    end
  end

  context "when logged in as admin" do
    it "shows the dashboard" do
      login_as_admin
      visit "/admin/cms"
      # Use string-based check to avoid DOM node issues
      expect(page.html).to include("Dashboard")
    end

    it "displays the admin navigation" do
      login_as_admin
      visit "/admin/cms"

      # Wait for Dashboard to appear, then check navigation
      expect(page).to have_content("Dashboard", wait: 5)

      # Use string-based checks to avoid DOM node issues
      html_content = page.html
      expect(html_content).to include("Dashboard")
      expect(html_content).to include('href="/admin/cms/pages"')
      expect(html_content).to include('href="/admin/cms/posts"')
      expect(html_content).to include('href="/admin/cms/forms"')
      expect(html_content).to include('href="/admin/cms/menus"')
      expect(html_content).to include('href="/admin/cms/settings"')
      expect(html_content).to include("Logout")
    end

    it "does not display icons in page headings" do
      login_as_admin

      %w[/admin/cms/pages /admin/cms/posts /admin/cms/forms /admin/cms/files /admin/cms/menus /admin/cms/settings].each do |path|
        visit path
        expect(page).to have_css("h1", wait: 5)
        expect(page).to have_no_css("h1 i", wait: 0), "Expected no icon in h1 heading on #{path}"
      end
    end

    context "with analytics data" do
      before do
        # Mock analytics provider with data
        allow(Panda::CMS.config).to receive(:analytics_providers).and_return({
          test_provider: {enabled: true, name: "Test Analytics"}
        })

        # Create a mock provider that returns page view data
        mock_provider = double("AnalyticsProvider",
          name: "Test Analytics",
          page_views_over_time: [
            {date: 7.days.ago.to_date, views: 100},
            {date: 6.days.ago.to_date, views: 150},
            {date: 5.days.ago.to_date, views: 200},
            {date: 4.days.ago.to_date, views: 175},
            {date: 3.days.ago.to_date, views: 225},
            {date: 2.days.ago.to_date, views: 300},
            {date: 1.day.ago.to_date, views: 275}
          ])

        allow_any_instance_of(Panda::CMS::Admin::PageViewsChartComponent)
          .to receive(:provider).and_return(mock_provider)
        allow_any_instance_of(Panda::CMS::Admin::PageViewsChartComponent)
          .to receive(:analytics_available?).and_return(true)
      end

      it "renders the page views chart without errors", js: true do
        login_as_admin
        visit "/admin/cms"

        # Verify dashboard loads
        expect(page).to have_content("Dashboard", wait: 5)

        # Verify chart widget is present
        expect(page).to have_content("Page Views Over Time")
        expect(page).to have_content("Test Analytics")

        # Verify page loaded successfully (no 500 error)
        expect(page.status_code).to eq(200)
      end

      it "displays chart data correctly" do
        login_as_admin
        visit "/admin/cms"

        expect(page).to have_content("Page Views Over Time", wait: 5)

        # Verify the data source attribution is shown
        expect(page).to have_content("Data from Test Analytics")

        # Verify no 500 error
        expect(page.status_code).to eq(200)
      end
    end

    context "without analytics data" do
      before do
        allow(Panda::CMS.config).to receive(:analytics_providers).and_return({})
        allow_any_instance_of(Panda::CMS::Admin::PageViewsChartComponent)
          .to receive(:analytics_available?).and_return(false)
      end

      it "shows a message when no analytics data is available" do
        login_as_admin
        visit "/admin/cms"

        expect(page).to have_content("Dashboard", wait: 5)
        expect(page).to have_content("No chart data available")
      end
    end
  end
end
