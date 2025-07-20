require "rails_helper"

RSpec.describe Panda::CMS::Page, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:panda_cms_template_id) }

    it "validates that path starts with a forward slash" do
      page = build(:page, path: "no-slash")
      expect(page).not_to be_valid
      expect(page.errors[:path]).to include("must start with a forward slash")
    end

    it "validates parent presence for non-root pages" do
      page = build(:page, path: "/some-page", parent: nil)
      expect(page).not_to be_valid
      expect(page.errors[:parent]).to include("must exist")
    end

    it "allows root page without parent" do
      page = build(:page, path: "/", parent: nil)
      expect(page).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:template).class_name("Panda::CMS::Template") }
    it { should have_many(:block_contents).class_name("Panda::CMS::BlockContent").dependent(:destroy) }
    it { should have_many(:blocks).through(:block_contents) }
    it { should have_many(:menu_items).class_name("Panda::CMS::MenuItem") }
    it { should have_many(:menus).through(:menu_items) }
  end

  describe "path handling" do
    let(:homepage) { create(:page, path: "/", parent: nil) }
    let(:about_page) { create(:page, path: "/about", parent: homepage) }
    let(:template) { create(:template) }

    context "when creating a page with parent path already included" do
      it "does not duplicate the parent path" do
        # Simulate what JavaScript sends: full path including parent
        page = Panda::CMS::Page.new(
          title: "Nested Page",
          path: "/about/nested-page",
          parent: about_page,
          panda_cms_template_id: template.id
        )

        # Simulate controller logic
        if page.parent && page.parent.path != "/" && page.path.present?
          unless page.path.start_with?(page.parent.path)
            page.path = page.parent.path + page.path
          end
        end

        expect(page.path).to eq("/about/nested-page")
        expect(page).to be_valid
      end
    end

    context "when creating a page without parent path included" do
      it "prepends the parent path" do
        # Simulate a case where only the slug is provided
        page = Panda::CMS::Page.new(
          title: "Nested Page",
          path: "/nested-page",
          parent: about_page,
          panda_cms_template_id: template.id
        )

        # Simulate controller logic
        if page.parent && page.parent.path != "/" && page.path.present?
          unless page.path.start_with?(page.parent.path)
            page.path = page.parent.path + page.path
          end
        end

        expect(page.path).to eq("/about/nested-page")
        expect(page).to be_valid
      end
    end

    context "when creating deeply nested pages" do
      let(:level_two) { create(:page, path: "/about/services", parent: about_page) }

      it "correctly handles third-level page paths" do
        # Simulate JavaScript sending full path
        page = Panda::CMS::Page.new(
          title: "Deep Page",
          path: "/about/services/deep-page",
          parent: level_two,
          panda_cms_template_id: template.id
        )

        # Simulate controller logic
        if page.parent && page.parent.path != "/" && page.path.present?
          unless page.path.start_with?(page.parent.path)
            page.path = page.parent.path + page.path
          end
        end

        expect(page.path).to eq("/about/services/deep-page")
        expect(page).to be_valid
      end
    end
  end

  describe "unique path validation" do
    let(:homepage) { create(:page, path: "/", parent: nil) }
    let(:about_page) { create(:page, path: "/about", parent: homepage) }
    let(:services_page) { create(:page, path: "/services", parent: homepage) }

    it "allows same slug in different parent contexts" do
      # Create /about/team
      create(:page,
        title: "Team",
        path: "/about/team",
        parent: about_page)

      # Should allow /services/team
      team_under_services = build(:page,
        title: "Team",
        path: "/services/team",
        parent: services_page)

      expect(team_under_services).to be_valid
    end

    it "prevents duplicate paths in same parent context" do
      create(:page,
        title: "Existing",
        path: "/about/existing",
        parent: about_page)

      duplicate_page = build(:page,
        title: "Another Page",
        path: "/about/existing",
        parent: about_page)

      expect(duplicate_page).not_to be_valid
      expect(duplicate_page.errors[:path]).to include("has already been taken in this section")
    end
  end

  describe "callbacks" do
    let(:template) { create(:template) }
    let(:page) { create(:page, template: template) }

    describe "#generate_content_blocks" do
      it "creates block contents for all template blocks" do
        block1 = create(:block, template: template)
        block2 = create(:block, template: template)

        expect {
          page.send(:generate_content_blocks)
        }.to change { page.block_contents.count }.by(2)

        expect(page.block_contents.map(&:panda_cms_block_id)).to match_array([block1.id, block2.id])
      end

      it "doesn't duplicate existing block contents" do
        block = create(:block, template: template)
        create(:block_content, page: page, block: block)

        expect {
          page.send(:generate_content_blocks)
        }.not_to change { page.block_contents.count }
      end
    end

    describe "#create_redirect_if_path_changed" do
      it "creates a redirect when path changes" do
        page = create(:page, path: "/old-path")

        expect {
          page.update!(path: "/new-path")
        }.to change { Panda::CMS::Redirect.count }.by(1)

        redirect = Panda::CMS::Redirect.last
        expect(redirect.origin_path).to eq("/old-path")
        expect(redirect.destination_path).to eq("/new-path")
        expect(redirect.status_code).to eq(301)
      end

      it "doesn't create redirect when path doesn't change" do
        page = create(:page, path: "/same-path")

        expect {
          page.update!(title: "New Title")
        }.not_to change { Panda::CMS::Redirect.count }
      end
    end
  end
end
