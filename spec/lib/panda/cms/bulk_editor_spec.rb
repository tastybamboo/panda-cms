# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::BulkEditor, type: :model do
  # Load fixtures at class level
  fixtures :panda_cms_templates, :panda_cms_pages, :panda_cms_menus,
    :panda_cms_menu_items, :panda_cms_blocks, :panda_cms_block_contents

  # Helper to create a test user
  let(:test_user) do
    Panda::Core::User.create!(
      email: "test@example.com",
      name: "Test User",
      is_admin: true
    )
  end

  # Helper to create test template
  def create_test_template(name, file_path)
    allow(File).to receive(:file?).and_return(true)
    template = Panda::CMS::Template.find_or_create_by!(
      name: name,
      file_path: file_path
    )
    RSpec::Mocks.space.proxy_for(File).reset
    template
  end

  before do
    # Ensure we have a user for posts
    @user = test_user

    # Create templates needed for fixtures
    create_test_template("Homepage", "layouts/homepage")
    create_test_template("Page", "layouts/page")
    create_test_template("Different Page", "layouts/different_page")

    # Clear any existing posts to avoid slug conflicts
    Panda::CMS::Post.delete_all

    # Create posts with user reference
    @post1 = Panda::CMS::Post.create!(
      title: "Test Post 1",
      slug: "/#{Time.current.strftime("%Y/%m")}/test-post-1",
      status: "active",
      user: @user,
      published_at: Time.current
    )

    @post2 = Panda::CMS::Post.create!(
      title: "Test Post 2",
      slug: "/#{Time.current.strftime("%Y/%m")}/test-post-2",
      status: "draft",
      user: @user,
      published_at: nil
    )
  end

  describe ".export" do
    it "returns a JSON string" do
      result = described_class.export
      expect(result).to be_a(String)
      expect { JSON.parse(result) }.not_to raise_error
    end

    it "includes all content sections" do
      data = JSON.parse(described_class.export)

      expect(data).to have_key("pages")
      expect(data).to have_key("posts")
      expect(data).to have_key("menus")
      expect(data).to have_key("templates")
      expect(data).to have_key("settings")
    end

    describe "page export" do
      it "exports pages with all core fields" do
        data = JSON.parse(described_class.export)
        homepage = data["pages"]["/"]

        expect(homepage).to be_present
        expect(homepage["title"]).to eq("Home")
        expect(homepage["template"]).to eq("Homepage")
        expect(homepage["parent"]).to be_nil
        expect(homepage["status"]).to eq("active")
        expect(homepage["page_type"]).to eq("standard")
      end

      it "exports nested pages with parent references" do
        data = JSON.parse(described_class.export)
        about_page = data["pages"]["/about"]
        team_page = data["pages"]["/about/team"]

        expect(about_page["parent"]).to eq("/")
        expect(team_page["parent"]).to eq("/about")
      end

      it "exports page block contents" do
        data = JSON.parse(described_class.export)
        homepage = data["pages"]["/"]

        expect(homepage["contents"]).to be_present
        expect(homepage["contents"]["hero_content"]).to be_present
        # Content is a JSON string that gets parsed into a hash
        content = homepage["contents"]["hero_content"]["content"]
        expect(content).to be_a(Hash)
        expect(content["blocks"].first["data"]["text"]).to include("ice cream")
      end

      it "handles pages with empty block contents" do
        # Create a page - it will have block definitions but no content
        Panda::CMS::Page.create!(
          path: "/empty",
          title: "Empty Page",
          template: Panda::CMS::Template.first,
          parent: Panda::CMS::Page.find_by(path: "/")
        )

        # Since template blocks are auto-generated, the page will have empty block contents
        data = JSON.parse(described_class.export)
        # The page should be exported with its template blocks, even if content is empty
        expect(data["pages"]["/empty"]).to be_present
        expect(data["pages"]["/empty"]["title"]).to eq("Empty Page")
      end

      it "includes SEO fields when present" do
        page = Panda::CMS::Page.find_by(path: "/")
        page.update!(
          seo_title: "Test SEO Title",
          seo_description: "Test SEO Description",
          seo_keywords: "test, keywords"
        )

        data = JSON.parse(described_class.export)
        homepage = data["pages"]["/"]

        expect(homepage["seo_title"]).to eq("Test SEO Title")
        expect(homepage["seo_description"]).to eq("Test SEO Description")
        expect(homepage["seo_keywords"]).to eq("test, keywords")
      end

      it "includes Open Graph fields when present" do
        page = Panda::CMS::Page.find_by(path: "/")
        page.update!(
          og_title: "Test OG Title",
          og_description: "Test OG Description",
          og_type: "article"
        )

        data = JSON.parse(described_class.export)
        homepage = data["pages"]["/"]

        expect(homepage["og_title"]).to eq("Test OG Title")
        expect(homepage["og_description"]).to eq("Test OG Description")
        expect(homepage["og_type"]).to eq("article")
      end
    end

    describe "post export" do
      it "exports posts with all core fields" do
        data = JSON.parse(described_class.export)
        post = data["posts"].find { |p| p["slug"] == @post1.slug }

        expect(post).to be_present
        expect(post["title"]).to eq("Test Post 1")
        expect(post["status"]).to eq("active")
        expect(post["user_email"]).to eq(@user.email)
      end

      it "exports draft posts" do
        data = JSON.parse(described_class.export)
        post = data["posts"].find { |p| p["slug"] == @post2.slug }

        expect(post).to be_present
        expect(post["status"]).to eq("draft")
      end

      it "includes SEO fields for posts when present" do
        @post1.update!(
          seo_title: "Post SEO Title",
          seo_description: "Post SEO Description"
        )

        data = JSON.parse(described_class.export)
        post = data["posts"].find { |p| p["slug"] == @post1.slug }

        expect(post["seo_title"]).to eq("Post SEO Title")
        expect(post["seo_description"]).to eq("Post SEO Description")
      end
    end

    describe "menu export" do
      it "exports static menus with items" do
        data = JSON.parse(described_class.export)
        main_menu = data["menus"].find { |m| m["name"] == "Main Menu" }

        expect(main_menu).to be_present
        expect(main_menu["kind"]).to eq("static")
        expect(main_menu["items"]).to be_an(Array)
        expect(main_menu["items"].length).to be > 0
      end

      it "exports auto menus with start_page_path" do
        # Create an auto menu
        Panda::CMS::Menu.create!(
          name: "Auto Test Menu",
          kind: "auto",
          start_page: Panda::CMS::Page.find_by(path: "/")
        )

        data = JSON.parse(described_class.export)
        exported_menu = data["menus"].find { |m| m["name"] == "Auto Test Menu" }

        expect(exported_menu).to be_present
        expect(exported_menu["kind"]).to eq("auto")
        expect(exported_menu["start_page_path"]).to eq("/")
      end

      it "exports menu items with page references" do
        data = JSON.parse(described_class.export)
        main_menu = data["menus"].find { |m| m["name"] == "Main Menu" }
        home_item = main_menu["items"].find { |i| i["text"] == "Home" }

        expect(home_item).to be_present
        expect(home_item["page_path"]).to eq("/")
      end
    end
  end

  describe ".import" do
    let(:export_data) { described_class.export }

    it "returns a debug hash" do
      data = JSON.parse(export_data)
      result = described_class.import(data.to_json)

      expect(result).to be_a(Hash)
      expect(result).to have_key(:success)
      expect(result).to have_key(:error)
      expect(result).to have_key(:warning)
    end

    it "imports without errors when re-importing existing data" do
      data = JSON.parse(export_data)
      result = described_class.import(data.to_json)

      expect(result[:error]).to be_empty
    end

    describe "page import" do
      it "creates a new page" do
        data = JSON.parse(export_data)
        template = Panda::CMS::Template.first

        data["pages"]["/new-page"] = {
          "title" => "New Page",
          "template" => template.name,
          "parent" => "/",
          "status" => "active",
          "page_type" => "standard",
          "contents" => {}
        }

        expect {
          described_class.import(data.to_json)
        }.to change(Panda::CMS::Page, :count).by(1)

        new_page = Panda::CMS::Page.find_by(path: "/new-page")
        expect(new_page).to be_present
        expect(new_page.title).to eq("New Page")
      end

      it "updates an existing page title" do
        page = Panda::CMS::Page.find_by(path: "/about")
        original_title = page.title

        data = JSON.parse(export_data)
        data["pages"]["/about"]["title"] = "Updated About Title"

        described_class.import(data.to_json)

        page.reload
        expect(page.title).to eq("Updated About Title")
        expect(page.title).not_to eq(original_title)
      end

      it "updates page contents" do
        data = JSON.parse(export_data)
        data["pages"]["/"]["contents"]["hero_content"]["content"] = {"blocks" => [{"type" => "paragraph", "data" => {"text" => "Updated Hero"}}], "version" => "2.30.7"}

        described_class.import(data.to_json)

        page = Panda::CMS::Page.find_by(path: "/")
        block = Panda::CMS::Block.find_by(key: "hero_content", template: page.template)
        block_content = Panda::CMS::BlockContent.find_by(page: page, block: block)

        # Content is stored as JSON string, parse it if needed
        content = block_content.content.is_a?(String) ? JSON.parse(block_content.content) : block_content.content
        expect(content["blocks"].first["data"]["text"]).to include("Updated Hero")
      end

      it "imports SEO fields" do
        data = JSON.parse(export_data)
        data["pages"]["/"]["seo_title"] = "Imported SEO Title"
        data["pages"]["/"]["seo_description"] = "Imported SEO Description"

        described_class.import(data.to_json)

        page = Panda::CMS::Page.find_by(path: "/")
        expect(page.seo_title).to eq("Imported SEO Title")
        expect(page.seo_description).to eq("Imported SEO Description")
      end
    end

    describe "post import" do
      it "creates a new post" do
        data = JSON.parse(export_data)
        slug = "/#{Time.current.strftime("%Y/%m")}/new-post"
        data["posts"] << {
          "slug" => slug,
          "title" => "New Post",
          "status" => "draft",
          "user_email" => @user.email,
          "contents" => {}
        }

        expect {
          described_class.import(data.to_json)
        }.to change(Panda::CMS::Post, :count).by(1)

        new_post = Panda::CMS::Post.find_by(slug: slug)
        expect(new_post).to be_present
        expect(new_post.title).to eq("New Post")
      end

      it "updates an existing post title" do
        data = JSON.parse(export_data)
        post_data = data["posts"].find { |p| p["slug"] == @post1.slug }
        post_data["title"] = "Updated Post Title"

        described_class.import(data.to_json)

        @post1.reload
        expect(@post1.title).to eq("Updated Post Title")
      end

      it "handles missing user gracefully" do
        data = JSON.parse(export_data)
        slug = "/#{Time.current.strftime("%Y/%m")}/orphan-post"
        data["posts"] << {
          "slug" => slug,
          "title" => "Orphan Post",
          "status" => "draft",
          "user_email" => "nonexistent@example.com",
          "contents" => {}
        }

        # Should fall back to first user
        expect {
          described_class.import(data.to_json)
        }.to change(Panda::CMS::Post, :count).by(1)

        orphan_post = Panda::CMS::Post.find_by(slug: slug)
        expect(orphan_post.user).to eq(Panda::Core::User.first)
      end
    end

    describe "menu import" do
      it "creates a new static menu" do
        data = JSON.parse(export_data)
        data["menus"] << {
          "name" => "New Menu",
          "kind" => "static",
          "items" => [
            {"text" => "Home", "page_path" => "/"}
          ]
        }

        expect {
          described_class.import(data.to_json)
        }.to change(Panda::CMS::Menu, :count).by(1)

        new_menu = Panda::CMS::Menu.find_by(name: "New Menu")
        expect(new_menu).to be_present
        expect(new_menu.kind).to eq("static")
        expect(new_menu.menu_items.count).to eq(1)
      end

      it "creates a new auto menu" do
        data = JSON.parse(export_data)
        data["menus"] << {
          "name" => "New Auto Menu",
          "kind" => "auto",
          "start_page_path" => "/"
        }

        expect {
          described_class.import(data.to_json)
        }.to change(Panda::CMS::Menu, :count).by(1)

        new_menu = Panda::CMS::Menu.find_by(name: "New Auto Menu")
        expect(new_menu).to be_present
        expect(new_menu.kind).to eq("auto")
        expect(new_menu.start_page.path).to eq("/")
      end

      it "updates static menu items" do
        main_menu = Panda::CMS::Menu.find_by(name: "Main Menu")
        original_count = main_menu.menu_items.count

        data = JSON.parse(export_data)
        menu_data = data["menus"].find { |m| m["name"] == "Main Menu" }
        menu_data["items"] << {"text" => "New Item", "page_path" => "/about"}

        described_class.import(data.to_json)

        main_menu.reload
        expect(main_menu.menu_items.count).to eq(original_count + 1)
        expect(main_menu.menu_items.find_by(text: "New Item")).to be_present
      end
    end

    describe "error handling" do
      it "handles invalid JSON" do
        expect {
          described_class.import("invalid json")
        }.to raise_error(JSON::ParserError)
      end

      it "reports errors for missing templates" do
        data = JSON.parse(export_data)
        data["pages"]["/test"] = {
          "title" => "Test",
          "template" => "NonexistentTemplate",
          "contents" => {}
        }

        result = described_class.import(data.to_json)

        expect(result[:error]).not_to be_empty
        expect(result[:error].first).to include("/test")
      end
    end
  end

  describe "data consistency" do
    it "exports and re-imports without data loss" do
      # Export current data
      export1 = described_class.export
      data1 = JSON.parse(export1)

      # Import it back
      result = described_class.import(export1)
      expect(result[:error]).to be_empty

      # Export again
      export2 = described_class.export
      data2 = JSON.parse(export2)

      # Compare exports (should be identical)
      expect(data2["pages"].keys).to match_array(data1["pages"].keys)
      expect(data2["posts"].length).to eq(data1["posts"].length)
      expect(data2["menus"].length).to eq(data1["menus"].length)
    end
  end

  describe "schema synchronization" do
    it "exports all important Page database columns" do
      # Get all Page columns
      page_columns = Panda::CMS::Page.column_names

      # Columns that should be excluded (internal Rails/tree fields)
      excluded_columns = %w[
        lft rgt depth children_count
        cached_last_updated_at
        created_at updated_at
      ]

      # Columns that should be exported
      expected_columns = page_columns - excluded_columns

      # Export and check
      data = JSON.parse(described_class.export)
      page_data = data["pages"].values.first
      exported_keys = page_data.keys.map(&:to_s)

      # Map column names to expected export keys
      # Some columns get renamed in export (e.g., panda_cms_template_id -> template)
      column_mappings = {
        "panda_cms_template_id" => "template",
        "parent_id" => "parent",
        "og_image" => "og_image_url"
      }

      missing_fields = []
      expected_columns.each do |column|
        export_key = column_mappings[column] || column

        # Check if either the column name or its mapped name exists
        # or if the value is nil/empty (optional fields)
        page = Panda::CMS::Page.first
        value = begin
          page.send(column.to_sym)
        rescue
          nil
        end

        has_key = exported_keys.include?(export_key)
        is_empty = value.nil? || value.to_s.empty?

        unless has_key || is_empty
          missing_fields << column
        end
      end

      expect(missing_fields).to be_empty,
        "Missing Page fields in export: #{missing_fields.join(", ")}\n" \
        "Please update Panda::CMS::BulkEditor.extract_current_data to include these fields."
    end

    it "exports all important Post database columns" do
      post_columns = Panda::CMS::Post.column_names
      excluded_columns = %w[created_at updated_at]
      expected_columns = post_columns - excluded_columns

      data = JSON.parse(described_class.export)
      post_data = data["posts"].first
      next unless post_data # Skip if no posts

      exported_keys = post_data.keys.map(&:to_s)

      column_mappings = {
        "user_id" => "user_email",
        "author_id" => "author_email",
        "og_image" => "og_image_url"
      }

      missing_fields = []
      expected_columns.each do |column|
        export_key = column_mappings[column] || column

        post = Panda::CMS::Post.first
        next unless post

        value = begin
          post.send(column.to_sym)
        rescue
          nil
        end

        has_key = exported_keys.include?(export_key)
        is_empty = value.nil? || value.to_s.empty?

        unless has_key || is_empty
          missing_fields << column
        end
      end

      expect(missing_fields).to be_empty,
        "Missing Post fields in export: #{missing_fields.join(", ")}\n" \
        "Please update Panda::CMS::BulkEditor.extract_current_data to include these fields."
    end
  end
end
