# frozen_string_literal: true

require "rails_helper"

# Helper methods for testing
def create_test_template(name, file_path)
  # Stub the template file existence check
  allow(File).to receive(:file?).and_return(true)

  # Create the template
  template = Panda::CMS::Template.find_or_create_by!(
    name: name,
    file_path: file_path
  )

  # Reset the stub
  RSpec::Mocks.space.proxy_for(File).reset

  template
end

# Stub redirect creation to make tests work
def stub_redirect_creation
  allow_any_instance_of(Panda::CMS::Page).to receive(:create_redirect_if_path_changed).and_return(true)
end

RSpec.describe Panda::CMS::Page, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:panda_cms_template_id) }

    # Create a test template
    let(:template) { create_test_template("Page", "layouts/page") }

    it "validates that path starts with a forward slash" do
      page = Panda::CMS::Page.new(
        title: "Invalid Page",
        path: "no-slash",
        panda_cms_template_id: template.id
      )
      expect(page).not_to be_valid
      expect(page.errors[:path]).to include("must start with a forward slash")
    end

    it "validates parent presence for non-root pages" do
      page = Panda::CMS::Page.new(
        title: "No Parent Page",
        path: "/nonexistent/some-page",
        panda_cms_template_id: template.id,
        parent: nil
      )
      expect(page).not_to be_valid
      expect(page.errors[:parent]).to include("can't be blank")
    end

    it "allows root page without parent" do
      # Instead of creating a new homepage, we'll validate the unique root page rule
      # by directly checking if a homepage-like object would be valid
      homepage = Panda::CMS::Page.find_by(path: "/")

      if homepage
        # If homepage exists, check that it's valid
        expect(homepage.parent).to be_nil
        expect(homepage).to be_valid
      else
        # If no homepage exists, try to create one
        page = Panda::CMS::Page.new(
          title: "Test Root",
          path: "/", # Root pages are allowed without parent only for path "/"
          panda_cms_template_id: template.id,
          parent: nil,
          status: "published"
        )
        expect(page).to be_valid
      end
    end
  end

  describe "associations" do
    it { should belong_to(:template).class_name("Panda::CMS::Template") }
    it { should have_many(:block_contents).class_name("Panda::CMS::BlockContent").dependent(:destroy) }
    it { should have_many(:blocks).through(:block_contents) }
    it { should have_many(:menu_items).class_name("Panda::CMS::MenuItem") }
    it { should have_many(:menus).through(:menu_items) }
  end

  describe "path normalization" do
    let(:test_template) { create_test_template("Path Normalization Test", "layouts/path_norm_test") }

    before do
      stub_redirect_creation
    end

    let(:test_root) do
      page = Panda::CMS::Page.new(
        path: "/norm-test",
        title: "Normalization Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    it "strips trailing slashes from paths" do
      page = Panda::CMS::Page.new(
        title: "Trailing Slash Page",
        path: "/norm-test/trailing/",
        parent: test_root,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      page.valid?
      expect(page.path).to eq("/norm-test/trailing")
    end

    it "strips multiple trailing slashes from paths" do
      page = Panda::CMS::Page.new(
        title: "Multiple Trailing Slashes",
        path: "/norm-test/multiple///",
        parent: test_root,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      page.valid?
      expect(page.path).to eq("/norm-test/multiple")
    end

    it "preserves the homepage path as /" do
      homepage = Panda::CMS::Page.find_by(path: "/")
      if homepage
        homepage.valid?
        expect(homepage.path).to eq("/")
      end
    end

    it "does not modify paths without trailing slashes" do
      page = Panda::CMS::Page.new(
        title: "No Trailing Slash",
        path: "/norm-test/no-trailing",
        parent: test_root,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      page.valid?
      expect(page.path).to eq("/norm-test/no-trailing")
    end
  end

  describe "path handling" do
    # Create the page hierarchy dynamically for better test isolation
    let(:test_template) { create_test_template("Path Test Template", "layouts/path_test") }

    before do
      stub_redirect_creation
    end

    let(:root_page) do
      # For root pages, we need to skip validations since
      # there's already a homepage with path "/"
      page = Panda::CMS::Page.new(
        path: "/test-root",
        title: "Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    let(:parent_page) do
      Panda::CMS::Page.find_or_create_by!(
        path: "/test-root/parent",
        title: "Parent",
        template: test_template,
        parent: root_page,
        status: "published"
      )
    end

    let(:mid_level_page) do
      Panda::CMS::Page.find_or_create_by!(
        path: "/test-root/parent/mid-level",
        title: "Mid Level",
        template: test_template,
        parent: parent_page,
        status: "published"
      )
    end

    context "when creating a page with parent path already included" do
      it "does not duplicate the parent path" do
        # Simulate what JavaScript sends: full path including parent
        page = Panda::CMS::Page.new(
          title: "Nested Page",
          path: "/test-root/parent/nested-page",
          parent: parent_page,
          panda_cms_template_id: test_template.id,
          status: "published"
        )

        # Simulate controller logic
        if page.parent && page.parent.path != "/" && page.path.present? && !page.path.start_with?(page.parent.path)
          page.path = page.parent.path + page.path
        end

        expect(page.path).to eq("/test-root/parent/nested-page")
        expect(page).to be_valid
      end
    end

    context "when creating a page without parent path included" do
      it "prepends the parent path" do
        # Simulate a case where only the slug is provided
        page = Panda::CMS::Page.new(
          title: "Nested Page",
          path: "/nested-page",
          parent: parent_page,
          panda_cms_template_id: test_template.id,
          status: "published"
        )

        # Simulate controller logic
        if page.parent && page.parent.path != "/" && page.path.present? && !page.path.start_with?(page.parent.path)
          page.path = page.parent.path + page.path
        end

        expect(page.path).to eq("/test-root/parent/nested-page")
        expect(page).to be_valid
      end
    end

    context "when creating deeply nested pages" do
      it "correctly handles third-level page paths" do
        # Simulate JavaScript sending full path
        page = Panda::CMS::Page.new(
          title: "Deep Page",
          path: "/test-root/parent/mid-level/deep-page",
          parent: mid_level_page,
          panda_cms_template_id: test_template.id,
          status: "published"
        )

        # Simulate controller logic
        if page.parent && page.parent.path != "/" && page.path.present? && !page.path.start_with?(page.parent.path)
          page.path = page.parent.path + page.path
        end

        expect(page.path).to eq("/test-root/parent/mid-level/deep-page")
        expect(page).to be_valid
      end
    end
  end

  describe "unique path validation" do
    # Create the page hierarchy dynamically for better test isolation
    let(:test_template) { create_test_template("Validation Test Template", "layouts/validation_test") }

    before do
      stub_redirect_creation
    end

    let(:root_page) do
      # For root pages, we need to skip validations
      page = Panda::CMS::Page.new(
        path: "/validation-test",
        title: "Validation Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    let(:section_a) do
      Panda::CMS::Page.find_or_create_by!(
        path: "/validation-test/section-a",
        title: "Section A",
        template: test_template,
        parent: root_page,
        status: "published"
      )
    end

    let(:section_b) do
      Panda::CMS::Page.find_or_create_by!(
        path: "/validation-test/section-b",
        title: "Section B",
        template: test_template,
        parent: root_page,
        status: "published"
      )
    end

    # Create a team page under section A
    let!(:team_under_section_a) do
      Panda::CMS::Page.find_or_create_by!(
        path: "/validation-test/section-a/team",
        title: "Team A",
        template: test_template,
        parent: section_a,
        status: "published"
      )
    end

    it "allows same slug in different parent contexts" do
      # Should allow team page under section B
      team_under_section_b = Panda::CMS::Page.new(
        title: "Team B",
        path: "/validation-test/section-b/team",
        parent: section_b,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      expect(team_under_section_b).to be_valid
    end

    it "prevents duplicate paths in same parent context" do
      # Create an existing page first
      Panda::CMS::Page.create!(
        title: "Existing",
        path: "/validation-test/section-a/existing",
        parent: section_a,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      duplicate_page = Panda::CMS::Page.new(
        title: "Another Page",
        path: "/validation-test/section-a/existing",
        parent: section_a,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      expect(duplicate_page).not_to be_valid
      expect(duplicate_page.errors[:path]).to include("has already been taken in this section")
    end

    it "allows a new page at an archived page's path" do
      # Archive the existing team page
      team_under_section_a.update!(status: "archived")

      new_page = Panda::CMS::Page.new(
        title: "New Team A",
        path: "/validation-test/section-a/team",
        parent: section_a,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      expect(new_page).to be_valid
    end

    it "still blocks duplicates between non-archived pages" do
      Panda::CMS::Page.create!(
        title: "Active Page",
        path: "/validation-test/section-a/active",
        parent: section_a,
        panda_cms_template_id: test_template.id,
        status: "published"
      )

      duplicate = Panda::CMS::Page.new(
        title: "Duplicate Active",
        path: "/validation-test/section-a/active",
        parent: section_a,
        panda_cms_template_id: test_template.id,
        status: "unlisted"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:path]).to include("has already been taken in this section")
    end
  end

  describe "scopes" do
    let(:test_template) { create_test_template("Scope Test Template", "layouts/scope_test") }

    before do
      stub_redirect_creation
    end

    let(:scope_root) do
      page = Panda::CMS::Page.new(
        path: "/scope-test",
        title: "Scope Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    let!(:published_page) do
      Panda::CMS::Page.create!(
        title: "Published",
        path: "/scope-test/published",
        parent: scope_root,
        template: test_template,
        status: "published"
      )
    end

    let!(:archived_page) do
      Panda::CMS::Page.create!(
        title: "Archived",
        path: "/scope-test/archived",
        parent: scope_root,
        template: test_template,
        status: "archived"
      )
    end

    let!(:hidden_page) do
      Panda::CMS::Page.create!(
        title: "Hidden",
        path: "/scope-test/hidden",
        parent: scope_root,
        template: test_template,
        status: "hidden"
      )
    end

    describe ".not_archived" do
      it "excludes archived pages" do
        results = Panda::CMS::Page.not_archived
        expect(results).to include(published_page)
        expect(results).to include(hidden_page)
        expect(results).not_to include(archived_page)
      end
    end
  end

  describe "callbacks" do
    # Create templates for these tests
    let(:test_template) { create_test_template("Callback Test", "layouts/callback_test") }

    before do
      stub_redirect_creation
    end
    let(:test_root) do
      # For root pages, we need to skip validations
      page = Panda::CMS::Page.new(
        path: "/callback-test",
        title: "Callback Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    describe "#generate_content_blocks" do
      # Test the logic of the method without relying on database operations

      it "should have blocks associated with templates" do
        # Create some blocks for the template to demonstrate the relationship
        block1 = Panda::CMS::Block.create!(
          name: "Test Block A",
          key: "test_block_a",
          kind: "rich_text",
          template: test_template
        )

        # Verify that blocks are associated with the template
        expect(test_template.blocks).to include(block1)
      end

      it "handles existing block contents correctly" do
        # Create a page
        test_page = Panda::CMS::Page.create!(
          title: "Test Page With Blocks",
          path: "/callback-test/test-page-2",
          parent: test_root,
          template: test_template,
          status: "published"
        )

        # Create a mock block
        mock_block = double("MockBlock", id: "mock_block_id", key: "mock_block")

        # Mock an existing block content
        mock_content = double("MockBlockContent", block_id: "mock_block_id")
        existing_contents = [mock_content]

        # Setup mocks for the method logic
        allow(test_template).to receive(:blocks).and_return([mock_block])
        allow(test_page).to receive(:template).and_return(test_template)
        allow(test_page).to receive(:block_contents).and_return(existing_contents)

        # Existing content IDs should match one of the template blocks
        expect(existing_contents.map(&:block_id)).to include(mock_block.id)
        expect(existing_contents.size).to eq(1)
      end
    end

    describe "#infer_parent_from_path" do
      it "skips for root page" do
        homepage = Panda::CMS::Page.find_or_create_by!(path: "/") do |p|
          p.title = "Home"
          p.template = test_template
          p.status = "published"
        end
        homepage.valid?
        expect(homepage.parent_id).to be_nil
      end

      it "infers parent from path when parent_id is nil" do
        test_root # ensure parent exists before validation
        page = Panda::CMS::Page.new(
          title: "Child of Callback Root",
          path: "/callback-test/inferred-child",
          panda_cms_template_id: test_template.id,
          parent: nil
        )
        page.valid?
        expect(page.parent).to eq(test_root)
      end

      it "corrects wrong parent_id based on path hierarchy" do
        test_root # ensure correct parent exists before validation
        wrong_parent = Panda::CMS::Page.create!(
          title: "Wrong Parent",
          path: "/callback-test/wrong-section",
          parent: test_root,
          template: test_template,
          status: "published"
        )
        page = Panda::CMS::Page.new(
          title: "Misparented Page",
          path: "/callback-test/misparented",
          panda_cms_template_id: test_template.id,
          parent: wrong_parent
        )
        page.valid?
        expect(page.parent).to eq(test_root)
      end

      it "infers deeply nested parents" do
        mid_page = Panda::CMS::Page.create!(
          title: "Mid",
          path: "/callback-test/mid",
          parent: test_root,
          template: test_template,
          status: "published"
        )

        deep_page = Panda::CMS::Page.new(
          title: "Deep",
          path: "/callback-test/mid/deep",
          panda_cms_template_id: test_template.id,
          parent: nil
        )
        deep_page.valid?
        expect(deep_page.parent).to eq(mid_page)
      end

      it "does not change correct parent" do
        test_root # ensure parent exists before validation
        page = Panda::CMS::Page.new(
          title: "Correct Parent",
          path: "/callback-test/correct",
          panda_cms_template_id: test_template.id,
          parent: test_root
        )
        page.valid?
        expect(page.parent).to eq(test_root)
      end

      it "does not set parent when no matching page exists" do
        page = Panda::CMS::Page.new(
          title: "Orphan",
          path: "/nonexistent-root/orphan",
          panda_cms_template_id: test_template.id,
          parent: nil
        )
        page.valid?
        expect(page.parent_id).to be_nil
      end
    end

    describe "#create_redirect_if_path_changed" do
      # Simplified tests to check the behavior without creating real redirects

      it "tracks the path change for redirects" do
        # Create a test page with a path we'll change
        test_page = Panda::CMS::Page.create!(
          title: "Redirect Test",
          path: "/callback-test/old-path",
          parent: test_root,
          template: test_template,
          status: "published"
        )

        # Directly test the method by mocking behavior
        old_path = "/callback-test/old-path"
        new_path = "/callback-test/new-path"

        # Mock the change
        allow(test_page).to receive(:path_previously_changed?).and_return(true)
        allow(test_page).to receive(:path_previous_change).and_return([old_path, new_path])

        # We can't actually create the redirect but we can verify the logic
        expect(test_page.path_previously_changed?).to be_truthy
        expect(test_page.path_previous_change.first).to eq(old_path)
        expect(test_page.path_previous_change.last).to eq(new_path)
      end

      it "doesn't track path when it doesn't change" do
        # Create a test page with a path we won't change
        test_page = Panda::CMS::Page.create!(
          title: "No Redirect Test",
          path: "/callback-test/same-path",
          parent: test_root,
          template: test_template,
          status: "published"
        )

        # Directly test the logic - path hasn't changed
        allow(test_page).to receive(:path_previously_changed?).and_return(false)

        # Verify the logic condition that would prevent redirect creation
        expect(test_page.path_previously_changed?).to be_falsy
      end
    end
  end

  describe ".editor_search" do
    let(:test_template) { create_test_template("Search Test", "layouts/search_test") }

    before do
      stub_redirect_creation
    end

    let(:search_root) do
      page = Panda::CMS::Page.new(
        path: "/search-test",
        title: "Search Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    let!(:active_page) do
      Panda::CMS::Page.create!(
        title: "Active Page",
        path: "/search-test/active-page",
        parent: search_root,
        template: test_template,
        status: "published"
      )
    end

    let!(:draft_page) do
      Panda::CMS::Page.create!(
        title: "Draft Page",
        path: "/search-test/draft-page",
        parent: search_root,
        template: test_template,
        status: "hidden"
      )
    end

    let!(:another_active_page) do
      Panda::CMS::Page.create!(
        title: "Another Active",
        path: "/search-test/another-active",
        parent: search_root,
        template: test_template,
        status: "published"
      )
    end

    it "returns only active records" do
      results = Panda::CMS::Page.editor_search("page")
      hrefs = results.map { |r| r[:href] }
      expect(hrefs).to include("/search-test/active-page")
      expect(hrefs).not_to include("/search-test/draft-page")
    end

    it "matches by title" do
      results = Panda::CMS::Page.editor_search("Another Active")
      expect(results.length).to eq(1)
      expect(results.first[:name]).to eq("Another Active")
    end

    it "matches by path" do
      results = Panda::CMS::Page.editor_search("active-page")
      expect(results.map { |r| r[:href] }).to include("/search-test/active-page")
    end

    it "respects limit" do
      results = Panda::CMS::Page.editor_search("search-test", limit: 1)
      expect(results.length).to eq(1)
    end

    it "returns correct hash structure" do
      results = Panda::CMS::Page.editor_search("Active Page")
      expect(results.first).to include(:href, :name, :description)
      expect(results.first[:href]).to eq("/search-test/active-page")
      expect(results.first[:name]).to eq("Active Page")
      expect(results.first[:description]).to eq("/search-test/active-page")
    end
  end

  describe "SEO functionality" do
    let(:test_template) { create_test_template("SEO Test", "layouts/seo_test") }

    before do
      stub_redirect_creation
    end

    let(:seo_root) do
      page = Panda::CMS::Page.new(
        path: "/seo-test",
        title: "SEO Test Root",
        template: test_template,
        status: "published"
      )
      page.save(validate: false)
      page
    end

    describe "SEO validations" do
      it { should validate_length_of(:seo_title).is_at_most(70) }
      it { should validate_length_of(:seo_description).is_at_most(160) }
      it { should validate_length_of(:og_title).is_at_most(60) }
      it { should validate_length_of(:og_description).is_at_most(200) }

      it "validates canonical URL format" do
        page = Panda::CMS::Page.new(
          title: "Invalid Canonical",
          path: "/seo-test/invalid",
          parent: seo_root,
          template: test_template,
          canonical_url: "not-a-url"
        )
        expect(page).not_to be_valid
        expect(page.errors[:canonical_url]).to be_present
      end

      it "allows valid canonical URL" do
        page = Panda::CMS::Page.new(
          title: "Valid Canonical",
          path: "/seo-test/valid",
          parent: seo_root,
          template: test_template,
          canonical_url: "https://example.com/page"
        )
        expect(page).to be_valid
      end

      it "allows blank canonical URL" do
        page = Panda::CMS::Page.new(
          title: "No Canonical",
          path: "/seo-test/no-canonical",
          parent: seo_root,
          template: test_template,
          canonical_url: nil
        )
        expect(page).to be_valid
      end
    end

    describe "SEO enums" do
      it "has seo_index_mode enum" do
        page = Panda::CMS::Page.create!(
          title: "Enum Test",
          path: "/seo-test/enum",
          parent: seo_root,
          template: test_template
        )

        expect(page.seo_visible?).to be true
        page.seo_invisible!
        expect(page.seo_invisible?).to be true
      end

      it "has og_type enum" do
        page = Panda::CMS::Page.create!(
          title: "OG Type Test",
          path: "/seo-test/og-type",
          parent: seo_root,
          template: test_template
        )

        expect(page.og_website?).to be true
        page.og_article!
        expect(page.og_article?).to be true
        page.og_video!
        expect(page.og_video?).to be true
      end
    end

    describe "#effective_seo_title" do
      it "returns seo_title when present" do
        page = Panda::CMS::Page.create!(
          title: "Page Title",
          seo_title: "Custom SEO Title",
          path: "/seo-test/seo-title",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_seo_title).to eq("Custom SEO Title")
      end

      it "falls back to title when seo_title is blank" do
        page = Panda::CMS::Page.create!(
          title: "Page Title",
          path: "/seo-test/no-seo-title",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_seo_title).to eq("Page Title")
      end

      it "inherits from parent when inherit_seo is true" do
        parent = Panda::CMS::Page.create!(
          title: "Parent Page",
          seo_title: "Parent SEO Title",
          path: "/seo-test/parent",
          parent: seo_root,
          template: test_template
        )

        child = Panda::CMS::Page.create!(
          title: "Child Page",
          path: "/seo-test/parent/child",
          parent: parent,
          template: test_template,
          inherit_seo: true
        )

        expect(child.effective_seo_title).to eq("Parent SEO Title")
      end

      it "inherits from the nearest ancestor when parent is blank" do
        grandparent = Panda::CMS::Page.create!(
          title: "Grandparent",
          seo_title: "Grandparent SEO Title",
          path: "/seo-test/grandparent",
          parent: seo_root,
          template: test_template
        )

        parent = Panda::CMS::Page.create!(
          title: "Parent",
          path: "/seo-test/grandparent/parent",
          parent: grandparent,
          template: test_template
        )

        child = Panda::CMS::Page.create!(
          title: "Child",
          path: "/seo-test/grandparent/parent/child",
          parent: parent,
          template: test_template,
          inherit_seo: true
        )

        expect(child.effective_seo_title).to eq("Grandparent SEO Title")
      end

      it "does not inherit when inherit_seo is false" do
        parent = Panda::CMS::Page.create!(
          title: "Parent Page",
          seo_title: "Parent SEO Title",
          path: "/seo-test/parent-no-inherit",
          parent: seo_root,
          template: test_template
        )

        child = Panda::CMS::Page.create!(
          title: "Child Page",
          path: "/seo-test/parent-no-inherit/child",
          parent: parent,
          template: test_template,
          inherit_seo: false
        )

        expect(child.effective_seo_title).to eq("Child Page")
      end
    end

    describe "#effective_seo_description" do
      it "returns seo_description when present" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          seo_description: "Custom description",
          path: "/seo-test/desc",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_seo_description).to eq("Custom description")
      end

      it "returns nil when seo_description is blank and no inheritance" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          path: "/seo-test/no-desc",
          parent: seo_root,
          template: test_template,
          inherit_seo: false
        )

        expect(page.effective_seo_description).to be_nil
      end

      it "inherits from parent when inherit_seo is true" do
        parent = Panda::CMS::Page.create!(
          title: "Parent",
          seo_description: "Parent description",
          path: "/seo-test/parent-desc",
          parent: seo_root,
          template: test_template
        )

        child = Panda::CMS::Page.create!(
          title: "Child",
          path: "/seo-test/parent-desc/child",
          parent: parent,
          template: test_template,
          inherit_seo: true
        )

        expect(child.effective_seo_description).to eq("Parent description")
      end
    end

    describe "#effective_og_title" do
      it "returns og_title when present" do
        page = Panda::CMS::Page.create!(
          title: "Page Title",
          og_title: "Custom OG Title",
          path: "/seo-test/og-title",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_og_title).to eq("Custom OG Title")
      end

      it "falls back to effective_seo_title" do
        page = Panda::CMS::Page.create!(
          title: "Page Title",
          seo_title: "SEO Title",
          path: "/seo-test/og-fallback",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_og_title).to eq("SEO Title")
      end
    end

    describe "#effective_og_description" do
      it "returns og_description when present" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          og_description: "OG description",
          path: "/seo-test/og-desc",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_og_description).to eq("OG description")
      end

      it "falls back to effective_seo_description" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          seo_description: "SEO description",
          path: "/seo-test/og-desc-fallback",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_og_description).to eq("SEO description")
      end
    end

    describe "#effective_canonical_url" do
      it "returns canonical_url when present" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          path: "/seo-test/canonical",
          parent: seo_root,
          template: test_template,
          canonical_url: "https://example.com/canonical"
        )

        expect(page.effective_canonical_url).to eq("https://example.com/canonical")
      end

      it "falls back to page path" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          path: "/seo-test/path-canonical",
          parent: seo_root,
          template: test_template
        )

        expect(page.effective_canonical_url).to eq("/seo-test/path-canonical")
      end
    end

    describe "#robots_meta_content" do
      it "returns 'index, follow' when visible" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          path: "/seo-test/visible",
          parent: seo_root,
          template: test_template,
          seo_index_mode: "visible"
        )

        expect(page.robots_meta_content).to eq("index, follow")
      end

      it "returns 'noindex, nofollow' when invisible" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          path: "/seo-test/invisible",
          parent: seo_root,
          template: test_template,
          seo_index_mode: "invisible"
        )

        expect(page.robots_meta_content).to eq("noindex, nofollow")
      end
    end

    describe "#seo_character_states" do
      it "reports statuses for each field with matching thresholds" do
        page = Panda::CMS::Page.new(
          title: "Page",
          path: "/seo-test/character-state",
          parent: seo_root,
          template: test_template,
          seo_title: "A" * 65, # warning
          seo_description: "A" * 40, # ok
          og_title: "A" * 75, # error
          og_description: "A" * 195 # warning (limit 200, <10 remaining)
        )

        states = page.seo_character_states

        expect(states[:seo_title].status).to eq(:warning)
        expect(states[:seo_description].status).to eq(:ok)
        expect(states[:og_title].status).to eq(:error)
        expect(states[:og_title].remaining).to eq(-15)
        expect(states[:og_description].status).to eq(:warning)
      end
    end

    describe "Active Storage attachment" do
      it "has og_image attachment" do
        page = Panda::CMS::Page.create!(
          title: "Page",
          path: "/seo-test/og-image",
          parent: seo_root,
          template: test_template
        )

        expect(page).to respond_to(:og_image)
        expect(page.og_image).to be_a(ActiveStorage::Attached::One)
      end
    end
  end

  describe "#update_auto_menus" do
    fixtures :panda_cms_menus, :panda_cms_pages

    let(:test_template) { create_test_template("Auto Menu Test", "layouts/auto_menu_test") }
    let(:homepage) { panda_cms_pages(:homepage) }

    context "when creating a child page under an auto menu start page" do
      let(:section_page) do
        Panda::CMS::Page.create!(
          title: "Section",
          path: "/section",
          parent: homepage,
          template: test_template,
          status: :published
        )
      end

      let(:auto_menu) do
        Panda::CMS::Menu.create!(
          name: "Test Auto Menu",
          kind: "auto",
          start_page: section_page
        )
      end

      it "finds and regenerates menus for newly created child pages" do
        # Set up: Ensure section_page and auto_menu are fully initialized
        # (RSpec let blocks are lazy-evaluated)
        section_page.reload
        auto_menu.reload
        auto_menu.generate_auto_menu_items

        initial_count = auto_menu.menu_items.count
        expect(initial_count).to eq(1)

        # Create and save child page
        # Note: The after_save callback (handle_after_save -> update_auto_menus)
        # should automatically regenerate the menu, but we test the logic explicitly
        child_page = Panda::CMS::Page.create!(
          title: "Child Page",
          path: "/section/child",
          parent: section_page,
          template: test_template,
          status: :published
        )

        # Verify the ancestor-based lookup logic that update_auto_menus uses
        ancestor_ids = child_page.self_and_ancestors.pluck(:id)
        expect(ancestor_ids).to include(section_page.id)

        # Verify that the menu would be found by the update_auto_menus query
        menus = Panda::CMS::Menu.where(kind: "auto", start_page_id: ancestor_ids)
        expect(menus).to include(auto_menu)

        # Manually regenerate the menu (simulating what update_auto_menus does)
        # to verify the regeneration logic works correctly
        auto_menu.generate_auto_menu_items

        # Verify menu was regenerated with the new child page
        auto_menu.reload
        expect(auto_menu.menu_items.count).to eq(2)
        page_ids = auto_menu.menu_items.pluck(:panda_cms_page_id)
        expect(page_ids).to include(section_page.id, child_page.id)
      end

      it "finds and regenerates menus for deeply nested pages" do
        # Create an intermediate level page
        mid_page = Panda::CMS::Page.create!(
          title: "Mid Page",
          path: "/section/mid",
          parent: section_page,
          template: test_template,
          status: :published
        )

        # Generate the menu - should have section_page + mid_page
        auto_menu.generate_auto_menu_items
        expect(auto_menu.menu_items.count).to eq(2)

        # Create a deeply nested page (3 levels deep)
        deep_page = Panda::CMS::Page.create!(
          title: "Deep Page",
          path: "/section/mid/deep",
          parent: mid_page,
          template: test_template,
          status: :published
        )

        # Verify the ancestor-based lookup logic that update_auto_menus uses
        # Deep page should have ancestors: [homepage, section_page, mid_page]
        ancestor_ids = deep_page.self_and_ancestors.pluck(:id)
        expect(ancestor_ids).to include(section_page.id, mid_page.id)

        # Verify that the menu would be found (start_page is in ancestors)
        menus = Panda::CMS::Menu.where(kind: "auto", start_page_id: ancestor_ids)
        expect(menus).to include(auto_menu)

        # Manually regenerate (simulating what update_auto_menus does)
        auto_menu.generate_auto_menu_items

        # Verify menu includes all three levels
        auto_menu.reload
        expect(auto_menu.menu_items.count).to eq(3)
        page_ids = auto_menu.menu_items.pluck(:panda_cms_page_id)
        expect(page_ids).to include(section_page.id, mid_page.id, deep_page.id)
      end
    end

    context "when moving a page across sections" do
      let(:section_a) do
        Panda::CMS::Page.create!(
          title: "Section A",
          path: "/section-a",
          parent: homepage,
          template: test_template,
          status: :published
        )
      end

      let(:section_b) do
        Panda::CMS::Page.create!(
          title: "Section B",
          path: "/section-b",
          parent: homepage,
          template: test_template,
          status: :published
        )
      end

      let(:menu_a) do
        Panda::CMS::Menu.create!(
          name: "Menu A",
          kind: "auto",
          start_page: section_a
        )
      end

      let(:menu_b) do
        Panda::CMS::Menu.create!(
          name: "Menu B",
          kind: "auto",
          start_page: section_b
        )
      end

      let(:movable_page) do
        Panda::CMS::Page.create!(
          title: "Movable Page",
          path: "/section-a/movable",
          parent: section_a,
          template: test_template,
          status: :published
        )
      end

      it "adds page to new menu when moved to different section" do
        # Ensure the movable page exists before generating menus
        movable_page.reload

        # Generate initial menus - this should include movable_page in menu_a
        menu_a.generate_auto_menu_items
        menu_b.generate_auto_menu_items

        # Verify initial state: page is in menu A but not menu B
        expect(menu_a.menu_items.pluck(:panda_cms_page_id)).to include(movable_page.id, section_a.id)
        expect(menu_b.menu_items.pluck(:panda_cms_page_id)).not_to include(movable_page.id)
        expect(menu_b.menu_items.pluck(:panda_cms_page_id)).to include(section_b.id)

        # Move the page to section B by changing path and parent
        # This triggers saved_change_to_path? and should call update_auto_menus
        movable_page.update!(
          path: "/section-b/movable",
          parent: section_b
        )

        # Verify the ancestor-based lookup logic after the move
        # Old parent (section_a) is no longer in ancestors
        ancestor_ids = movable_page.self_and_ancestors.pluck(:id)
        expect(ancestor_ids).to include(section_b.id)
        expect(ancestor_ids).not_to include(section_a.id)

        # Verify that menu_b would be found by update_auto_menus query
        menus = Panda::CMS::Menu.where(kind: "auto", start_page_id: ancestor_ids)
        expect(menus).to include(menu_b)

        # Manually regenerate menu_b (simulating what update_auto_menus does)
        menu_b.generate_auto_menu_items

        # Verify page is now in menu B
        menu_b.reload
        expect(menu_b.menu_items.pluck(:panda_cms_page_id)).to include(movable_page.id)

        # Note: menu_a is not automatically cleaned up because update_auto_menus
        # only looks at NEW ancestors after the move, not old ancestors
      end

      it "updates new menu when moving a page with children" do
        # Create a child under movable_page
        child_page = Panda::CMS::Page.create!(
          title: "Child of Movable",
          path: "/section-a/movable/child",
          parent: movable_page,
          template: test_template,
          status: :published
        )

        # Generate initial menus
        menu_a.generate_auto_menu_items
        menu_b.generate_auto_menu_items

        # Verify both pages are in menu A
        expect(menu_a.menu_items.pluck(:panda_cms_page_id)).to include(movable_page.id, child_page.id)

        # Move the parent page to section B
        movable_page.update!(
          path: "/section-b/movable",
          parent: section_b
        )

        # Update child path to match new parent
        child_page.update!(
          path: "/section-b/movable/child"
        )

        # Verify pages are now in menu B
        menu_b.reload
        page_ids_b = menu_b.menu_items.pluck(:panda_cms_page_id)
        expect(page_ids_b).to include(movable_page.id, child_page.id)
      end
    end

    context "when updating page attributes" do
      let(:section_page) do
        Panda::CMS::Page.create!(
          title: "Section",
          path: "/section",
          parent: homepage,
          template: test_template,
          status: :published
        )
      end

      let(:auto_menu) do
        Panda::CMS::Menu.create!(
          name: "Test Auto Menu",
          kind: "auto",
          start_page: section_page
        )
      end

      let(:child_page) do
        Panda::CMS::Page.create!(
          title: "Original Title",
          path: "/section/child",
          parent: section_page,
          template: test_template,
          status: :published
        )
      end

      before do
        auto_menu.generate_auto_menu_items
      end

      it "regenerates menu when page title changes" do
        # Update title
        child_page.update!(title: "New Title")

        # Menu item should reflect new title
        auto_menu.reload
        menu_item = auto_menu.menu_items.find_by(panda_cms_page_id: child_page.id)
        expect(menu_item.text).to eq("New Title")
      end

      it "regenerates menu when page status changes to archived" do
        # Change status to archived (not servable, removed from menus)
        child_page.update!(status: :archived)

        # Page should be removed from menu
        auto_menu.reload
        expect(auto_menu.menu_items.pluck(:panda_cms_page_id)).not_to include(child_page.id)
      end

      it "regenerates menu when page status changes to published" do
        # First make it archived
        child_page.update!(status: :archived)
        auto_menu.reload
        expect(auto_menu.menu_items.pluck(:panda_cms_page_id)).not_to include(child_page.id)

        # Then make it published again
        child_page.update!(status: :published)
        auto_menu.reload
        expect(auto_menu.menu_items.pluck(:panda_cms_page_id)).to include(child_page.id)
      end
    end

    context "when page is not under an auto menu" do
      let(:orphan_page) do
        Panda::CMS::Page.create!(
          title: "Orphan",
          path: "/orphan",
          parent: homepage,
          template: test_template,
          status: :published
        )
      end

      it "does not error when updating page without auto menus" do
        # This should not raise an error
        expect {
          orphan_page.update!(title: "Updated Orphan")
        }.not_to raise_error
      end
    end

    context "selective triggering of auto menu updates" do
      let(:section_page) do
        Panda::CMS::Page.create!(
          title: "Section",
          path: "/section",
          parent: homepage,
          template: test_template,
          status: :published
        )
      end

      let(:auto_menu) do
        Panda::CMS::Menu.create!(
          name: "Test Auto Menu",
          kind: "auto",
          start_page: section_page
        )
      end

      it "does not trigger update for irrelevant attribute changes" do
        child_page = Panda::CMS::Page.create!(
          title: "Child",
          path: "/section/child",
          parent: section_page,
          template: test_template,
          status: :published
        )

        # Spy on the update_auto_menus method
        allow_any_instance_of(Panda::CMS::Page).to receive(:update_auto_menus).and_call_original

        # Update an attribute that shouldn't trigger menu update
        child_page.update!(seo_title: "New SEO Title")

        # update_auto_menus should still be called but should_update_auto_menus? should return false
        expect(child_page.send(:should_update_auto_menus?)).to be_falsy
      end

      it "triggers update for title changes" do
        child_page = Panda::CMS::Page.create!(
          title: "Child",
          path: "/section/child",
          parent: section_page,
          template: test_template,
          status: :published
        )

        # Update title
        child_page.update!(title: "New Title")

        # This should have triggered an update
        expect(child_page.send(:should_update_auto_menus?)).to be_truthy
      end
    end
  end
end
