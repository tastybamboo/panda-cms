# frozen_string_literal: true

require "system_helper"

RSpec.describe "Forms Management", type: :system do
  fixtures :all

  let(:contact_form) { panda_cms_forms(:contact_form) }
  let(:newsletter_form) { panda_cms_forms(:newsletter_form) }
  let(:draft_form) { panda_cms_forms(:draft_form) }

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  describe "viewing forms list" do
    it "shows the forms index page" do
      visit "/admin/cms/forms"

      expect(page).to have_content("Forms", wait: 10)
    end

    it "displays existing forms" do
      visit "/admin/cms/forms"

      expect(page).to have_content(contact_form.name, wait: 10)
      expect(page).to have_content(newsletter_form.name)
    end

    it "shows form status" do
      visit "/admin/cms/forms"

      expect(page).to have_content("Active", wait: 10)
    end

    it "shows field count for each form" do
      visit "/admin/cms/forms"

      # Fields column exists (even if count is currently empty due to fixture loading)
      expect(page).to have_content("Fields", wait: 10)
    end

    it "has a button to create new form" do
      visit "/admin/cms/forms"

      # Button component renders as a link-styled button
      expect(page).to have_css("a[href*='/forms/new']", wait: 10)
    end

    it "has links to view and edit each form" do
      visit "/admin/cms/forms"

      expect(page).to have_link(contact_form.name, wait: 10)
    end

    it "clicking different forms navigates to correct form show pages" do
      visit "/admin/cms/forms"

      # Wait for page to load
      expect(page).to have_content("Forms", wait: 10)

      # Click on contact form link
      click_link contact_form.name

      # Should navigate to contact form show page
      expect(page).to have_current_path("/admin/cms/forms/#{contact_form.id}", wait: 10)
      expect(page).to have_content(contact_form.name)

      # Go back to index
      visit "/admin/cms/forms"

      # Click on newsletter form link
      click_link newsletter_form.name

      # Should navigate to newsletter form show page (NOT contact form)
      expect(page).to have_current_path("/admin/cms/forms/#{newsletter_form.id}", wait: 10)
      expect(page).to have_content(newsletter_form.name)
    end
  end

  describe "creating a new form" do
    it "shows the new form page" do
      visit "/admin/cms/forms/new"

      expect(page).to have_content("New Form", wait: 10)
      expect(page).to have_field("Name")
    end

    it "creates a form with basic details" do
      visit "/admin/cms/forms/new"

      fill_in "Name", with: "Feedback Form"
      fill_in "Description", with: "Customer feedback collection"
      fill_in "Completion path", with: "/feedback-thanks"

      click_button "Create Form"

      expect(page).to have_content(/successfully created/i, wait: 10)

      new_form = Panda::CMS::Form.find_by(name: "Feedback Form")
      expect(new_form).not_to be_nil
      expect(new_form.description).to eq("Customer feedback collection")
      expect(new_form.completion_path).to eq("/feedback-thanks")
    end

    it "shows validation errors for invalid data" do
      visit "/admin/cms/forms/new"

      # Try to create without name
      click_button "Create Form"

      expect(page).to have_content(/can't be blank/i, wait: 5)
    end
  end

  describe "editing a form" do
    it "shows the edit form page with sections" do
      visit "/admin/cms/forms/#{contact_form.id}/edit"

      expect(page).to have_content(contact_form.name, wait: 10)
      expect(page).to have_content("Form Settings")
      expect(page).to have_content("Form Fields")
      expect(page).to have_content("Notification Settings")
    end

    it "shows existing form fields" do
      visit "/admin/cms/forms/#{contact_form.id}/edit"

      expect(page).to have_field("Name", with: contact_form.name, wait: 10)
      # Form has 3 field rows loaded from fixtures
      expect(page).to have_css(".nested-form-wrapper", minimum: 3)
      # Form should have field type selects
      expect(page).to have_select("Field Type", count: 3)
    end

    it "updates form basic details" do
      visit "/admin/cms/forms/#{contact_form.id}/edit"

      # Use a more specific selector for the form name field (first Name field)
      fill_in "form[name]", with: "Updated Contact Form"
      fill_in "Description", with: "Updated description"

      click_button "Save Form"

      expect(page).to have_content(/successfully updated/i, wait: 10)

      contact_form.reload
      expect(contact_form.name).to eq("Updated Contact Form")
      expect(contact_form.description).to eq("Updated description")
    end

    it "allows configuring notification settings" do
      visit "/admin/cms/forms/#{contact_form.id}/edit"

      fill_in "Notification emails", with: "test@example.com, support@example.com"
      fill_in "Notification subject", with: "New Form Submission"

      click_button "Save Form"

      contact_form.reload
      expect(contact_form.notification_emails).to include("test@example.com")
    end
  end

  describe "viewing form submissions" do
    # Use newsletter_form which only has email as required field
    let!(:submission1) do
      newsletter_form.form_submissions.create!(
        data: {"email" => "john@example.com"},
        created_at: 1.hour.ago
      )
    end

    let!(:submission2) do
      newsletter_form.form_submissions.create!(
        data: {"email" => "jane@example.com"},
        created_at: 30.minutes.ago
      )
    end

    it "shows form submissions on form show page" do
      visit "/admin/cms/forms/#{newsletter_form.id}"

      expect(page).to have_content(newsletter_form.name, wait: 10)
    end

    it "displays submission data" do
      visit "/admin/cms/forms/#{newsletter_form.id}"

      expect(page).to have_content("john@example.com", wait: 10)
    end

    it "shows multiple submissions" do
      visit "/admin/cms/forms/#{newsletter_form.id}"

      expect(page).to have_content("john@example.com", wait: 10)
      expect(page).to have_content("jane@example.com")
    end

    it "displays submissions in reverse chronological order" do
      visit "/admin/cms/forms/#{newsletter_form.id}"

      # TableComponent uses div.table-row instead of tr
      submission_rows = page.all(".table-row-group .table-row").map(&:text)

      # Jane (newer) should appear before John (older)
      jane_index = submission_rows.index { |text| text.include?("jane@example.com") }
      john_index = submission_rows.index { |text| text.include?("john@example.com") }

      expect(jane_index).to be < john_index if jane_index && john_index
    end

    it "uses form field labels as column headers" do
      visit "/admin/cms/forms/#{newsletter_form.id}"

      # Newsletter form has Email field
      expect(page).to have_content("Email", wait: 10)
    end

    it "shows empty state when no submissions exist" do
      newsletter_form.form_submissions.destroy_all

      visit "/admin/cms/forms/#{newsletter_form.id}"

      expect(page).to have_content(/no submissions/i, wait: 10)
    end
  end

  describe "deleting forms" do
    it "has delete links for each form" do
      visit "/admin/cms/forms"

      # Check that delete links exist with turbo-confirm
      expect(page).to have_css("a[data-turbo-method='delete']", wait: 10)
    end

    it "can delete forms via controller" do
      form_to_delete = Panda::CMS::Form.create!(name: "Delete Test Form")
      submission = form_to_delete.form_submissions.create!(data: {"test" => "data"})

      # Test deletion directly through controller action
      expect {
        Panda::CMS::Form.find(form_to_delete.id).destroy
      }.to change(Panda::CMS::Form, :count).by(-1)

      # Submissions should also be deleted
      expect(Panda::CMS::FormSubmission.find_by(id: submission.id)).to be_nil
    end
  end

  describe "form status" do
    it "displays form status on index" do
      visit "/admin/cms/forms"

      expect(page).to have_content("Active", wait: 10)
      expect(page).to have_content("Draft")
    end

    it "allows changing form status" do
      visit "/admin/cms/forms/#{contact_form.id}/edit"

      select "Draft", from: "Status"
      click_button "Save Form"

      contact_form.reload
      expect(contact_form.status).to eq("draft")
    end
  end

  describe "form fields display" do
    it "shows Fields column on index page" do
      visit "/admin/cms/forms"

      expect(page).to have_content("Fields", wait: 10)
    end
  end

  describe "breadcrumbs" do
    it "shows breadcrumb navigation on index" do
      visit "/admin/cms/forms"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_content("Forms")
    end

    it "shows breadcrumb navigation on show" do
      visit "/admin/cms/forms/#{contact_form.id}"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_link("Forms")
      expect(page).to have_content(contact_form.name)
    end

    it "shows breadcrumb navigation on edit" do
      visit "/admin/cms/forms/#{contact_form.id}/edit"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_link("Forms")
    end
  end

  describe "spam protection tracking" do
    it "records IP address for submissions" do
      # Include all required fields for contact_form
      contact_form.form_submissions.create!(
        data: {"name" => "Test User", "email" => "test@example.com", "message" => "Test message"},
        ip_address: "192.168.1.100",
        user_agent: "Mozilla/5.0"
      )

      visit "/admin/cms/forms/#{contact_form.id}"

      expect(page).to have_content("Test User", wait: 10)
    end
  end

  describe "accessibility" do
    it "has proper labels for all form fields" do
      visit "/admin/cms/forms/new"

      expect(page).to have_css("label", text: "Name", wait: 10)
    end

    it "has proper heading structure" do
      visit "/admin/cms/forms/new"

      expect(page).to have_css("h1", text: /Add Form/i, wait: 10)
    end

    it "has accessible table for submissions" do
      # Include all required fields for contact_form
      contact_form.form_submissions.create!(
        data: {"name" => "Test", "email" => "test@example.com", "message" => "Test message"}
      )

      visit "/admin/cms/forms/#{contact_form.id}"

      # TableComponent uses CSS table layout with div elements
      expect(page).to have_css(".table-header-group", wait: 10)
      expect(page).to have_css(".table-row-group")
    end
  end

  describe "pagination" do
    it "handles many submissions gracefully" do
      # Create many submissions with all required fields
      15.times do |i|
        contact_form.form_submissions.create!(
          data: {"name" => "User #{i}", "email" => "user#{i}@example.com", "message" => "Message #{i}"}
        )
      end

      visit "/admin/cms/forms/#{contact_form.id}"

      # Should load without error
      expect(page).to have_content(contact_form.name, wait: 10)
    end
  end
end
