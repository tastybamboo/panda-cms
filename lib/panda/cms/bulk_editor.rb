# frozen_string_literal: true

require "json"

module Panda
  module CMS
    #
    # Bulk editor for site content in JSON format
    #
    # IMPORTANT: When adding new fields to Page, Post, or Menu models via migrations:
    # 1. Update the `extract_current_data` method to export the new fields
    # 2. Update the `import` method to import the new fields
    # 3. Run the spec at spec/lib/panda/cms/bulk_editor_spec.rb to verify completeness
    # 4. The spec will fail if database columns are not being exported
    #
    # This ensures content can be properly exported and imported between environments.
    #
    class BulkEditor
      #
      # Export all site content to a JSON string
      #
      # @return [String] The JSON data
      #
      def self.export
        data = extract_current_data
        JSON.pretty_generate(data)
      end

      #
      # Import site content from a JSON string
      #
      # @param json_data [String] The JSON data to import
      # @return [Hash] A hash of debug information
      #
      def self.import(json_data)
        # See if we can parse the JSON
        new_data = JSON.parse(json_data)
        current_data = extract_current_data

        debug = {
          success: [],
          error: [],
          warning: []
        }

        # Make sure templates are up to date
        Panda::CMS::Template.generate_missing_blocks

        # Run through the new data and compare it to the current data
        new_data["pages"].each do |path, page_data|
          if current_data["pages"][path].nil?
            begin
              page = Panda::CMS::Page.create!(
                path: path,
                title: page_data["title"],
                status: page_data["status"] || "active",
                page_type: page_data["page_type"] || "standard",
                template: Panda::CMS::Template.find_by(name: page_data["template"]),
                parent: Panda::CMS::Page.find_by(path: page_data["parent"]),
                # SEO fields
                seo_title: page_data["seo_title"],
                seo_description: page_data["seo_description"],
                seo_keywords: page_data["seo_keywords"],
                seo_index_mode: page_data["seo_index_mode"] || "visible",
                canonical_url: page_data["canonical_url"],
                # Open Graph fields
                og_type: page_data["og_type"] || "website",
                og_title: page_data["og_title"],
                og_description: page_data["og_description"]
              )
            rescue => e
              debug[:error] << "Failed to create page '#{path}': #{e.message}"
              next
            end

            if !page
              debug[:error] << "Unhandled: page '#{path}' does not exist in the current data and cannot be created"
              next
            else
              debug[:success] << "Created page '#{path}' with title '#{page_data["title"]}'"
            end
          else
            page = Panda::CMS::Page.find_by(path: path)

            # Check if template changed
            if page_data["template"] != current_data["pages"][path]["template"]
              # TODO: Handle page template changes
              debug[:error] << "Page '#{path}' template is '#{current_data["pages"][path]["template"]}' and cannot be changed to '#{page_data["template"]}' without manual intervention"
            else
              # Update page fields
              begin
                page.update!(
                  title: page_data["title"],
                  status: page_data["status"] || page.status,
                  page_type: page_data["page_type"] || page.page_type,
                  parent: Panda::CMS::Page.find_by(path: page_data["parent"]) || page.parent,
                  # SEO fields
                  seo_title: page_data["seo_title"],
                  seo_description: page_data["seo_description"],
                  seo_keywords: page_data["seo_keywords"],
                  seo_index_mode: page_data["seo_index_mode"] || page.seo_index_mode,
                  canonical_url: page_data["canonical_url"],
                  # Open Graph fields
                  og_type: page_data["og_type"] || page.og_type,
                  og_title: page_data["og_title"],
                  og_description: page_data["og_description"]
                )
                debug[:success] << "Updated page '#{path}'"
              rescue => e
                debug[:error] << "Failed to update page '#{path}': #{e.message}"
              end
            end
          end

          page_data["contents"]&.each do |key, block_data|
            content = block_data["content"]

            if current_data.dig("pages", path, "contents", key).nil?
              raise "Unknown page 1" if page.nil?

              block = Panda::CMS::Block.find_or_create_by(key: key, template: page.template) do |block_meta|
                block_meta.name = key.titleize
              end

              unless block
                debug[:error] << "Error creating block '#{key.titleize}' on page '#{page.title}'"
                next
              end

              block_content = Panda::CMS::BlockContent.find_or_create_by(block: block, page: page)
              # block_content.content = HTMLEntities.new.encode(content, :named)
              block_content.content = content

              begin
                block_content.save!

                if block_content.content != content
                  debug[:error] << "Failed to save content for '#{block.name}' on page '#{page.title}'"
                else
                  debug[:success] << "Created '#{block.name}' content on page '#{page.title}'"
                end
              rescue => e
                debug[:error] << "Failed to create '#{block.name}' content on page '#{page.title}': #{e.message}"
              end
            elsif content != current_data["pages"][path]["contents"][key]["content"]
              # Content has changed
              raise "Unknown page 2" if page.nil?

              block = Panda::CMS::Block.find_by(key: key, template: page.template)
              if Panda::CMS::BlockContent.find_by(page: page, block: block)&.update(content: content)
                debug[:success] << "Updated '#{key.titleize}' content on page '#{page.title}'"
              else
                debug[:error] << "Failed to update '#{key.titleize}' content on page '#{page.title}'"
              end
            end
          end
        end

        # Posts
        new_data["posts"]&.each do |post_data|
          slug = post_data["slug"]
          post = Panda::CMS::Post.find_by(slug: slug)

          # Find or create user by email
          user = if post_data["user_email"]
            Panda::Core::User.find_by(email: post_data["user_email"]) || Panda::Core::User.first
          else
            Panda::Core::User.first # Fallback to first user
          end

          author = if post_data["author_email"]
            Panda::Core::User.find_by(email: post_data["author_email"])
          end

          if post.nil?
            begin
              post = Panda::CMS::Post.create!(
                slug: slug,
                title: post_data["title"],
                status: post_data["status"] || "draft",
                published_at: post_data["published_at"],
                user: user,
                author: author,
                content: post_data["content"] || "",
                cached_content: post_data["cached_content"] || "",
                # SEO fields
                seo_title: post_data["seo_title"],
                seo_description: post_data["seo_description"],
                seo_keywords: post_data["seo_keywords"],
                seo_index_mode: post_data["seo_index_mode"] || "visible",
                canonical_url: post_data["canonical_url"],
                # Open Graph fields
                og_type: post_data["og_type"] || "article",
                og_title: post_data["og_title"],
                og_description: post_data["og_description"]
              )

              debug[:success] << "Created post '#{post.title}' (#{slug})"
            rescue => e
              debug[:error] << "Failed to create post '#{slug}': #{e.message}"
            end
          else
            # Update existing post
            begin
              post.update!(
                title: post_data["title"],
                status: post_data["status"] || post.status,
                published_at: post_data["published_at"] || post.published_at,
                author: author || post.author,
                content: post_data["content"] || post.content || "",
                cached_content: post_data["cached_content"] || post.cached_content || "",
                # SEO fields
                seo_title: post_data["seo_title"],
                seo_description: post_data["seo_description"],
                seo_keywords: post_data["seo_keywords"],
                seo_index_mode: post_data["seo_index_mode"] || post.seo_index_mode,
                canonical_url: post_data["canonical_url"],
                # Open Graph fields
                og_type: post_data["og_type"] || post.og_type,
                og_title: post_data["og_title"],
                og_description: post_data["og_description"]
              )

              debug[:success] << "Updated post '#{post.title}' (#{slug})"
            rescue => e
              debug[:error] << "Failed to update post '#{slug}': #{e.message}"
            end
          end
        end

        # Menus
        new_data["menus"]&.each do |menu_data|
          menu = Panda::CMS::Menu.find_by(name: menu_data["name"])

          if menu.nil?
            begin
              if menu_data["kind"] == "auto"
                start_page = Panda::CMS::Page.find_by(path: menu_data["start_page_path"])
                menu = Panda::CMS::Menu.create!(
                  name: menu_data["name"],
                  kind: "auto",
                  start_page: start_page
                )
                debug[:success] << "Created auto menu '#{menu.name}'"
              else
                menu = Panda::CMS::Menu.create!(
                  name: menu_data["name"],
                  kind: "static"
                )

                # Create menu items
                menu_data["items"]&.each do |item_data|
                  page = Panda::CMS::Page.find_by(path: item_data["page_path"]) if item_data["page_path"]
                  menu.menu_items.create!(
                    text: item_data["text"],
                    page: page,
                    external_url: item_data["external_url"]
                  )
                end

                debug[:success] << "Created static menu '#{menu.name}' with #{menu_data["items"]&.length || 0} items"
              end
            rescue => e
              debug[:error] << "Failed to create menu '#{menu_data["name"]}': #{e.message}"
            end
          else
            # Update existing menu
            if menu.kind != menu_data["kind"]
              debug[:warning] << "Menu '#{menu.name}' kind mismatch (#{menu.kind} vs #{menu_data["kind"]}). Skipping update."
              next
            end

            if menu_data["kind"] == "auto"
              start_page = Panda::CMS::Page.find_by(path: menu_data["start_page_path"])
              if menu.start_page != start_page
                menu.update(start_page: start_page)
                debug[:success] << "Updated auto menu '#{menu.name}' start page"
              end
            elsif menu_data["kind"] == "static"
              # Update static menu items
              menu.menu_items.destroy_all
              menu_data["items"]&.each do |item_data|
                page = Panda::CMS::Page.find_by(path: item_data["page_path"]) if item_data["page_path"]
                menu.menu_items.create!(
                  text: item_data["text"],
                  page: page,
                  external_url: item_data["external_url"]
                )
              end
              debug[:success] << "Updated static menu '#{menu.name}' with #{menu_data["items"]&.length || 0} items"
            end
          end
        end

        # Templates - skip as they are code-based

        debug
      end

      #
      # Extract the current data from the database into a standardised format
      #
      # Used both as the export format, and to compare imported data with for changes
      #
      # @visibility private
      def self.extract_current_data
        data = {
          "pages" => {},
          "posts" => [],
          "menus" => [],
          "templates" => {},
          "settings" => {}
        }

        # Pages
        Panda::CMS::Page.includes(:template).order("lft ASC").each do |page|
          data["pages"][page.path] ||= {}
        end

        # TODO: Eventually set the position of the block in the template, and then order from there rather than the name?
        Panda::CMS::BlockContent.includes(:block,
          page: [:template]).order("panda_cms_pages.lft ASC, panda_cms_blocks.key ASC").each do |block_content|
          # Skip block contents without a page (orphaned data)
          next unless block_content.page

          item = data["pages"][block_content.page.path] ||= {}
          item["id"] = block_content.page.id
          item["path"] = block_content.page.path
          item["title"] = block_content.page.title
          item["template"] = block_content.page.template.name
          item["parent"] = block_content.page.parent&.path
          item["status"] = block_content.page.status
          item["page_type"] = block_content.page.page_type
          # SEO fields
          item["seo_title"] = block_content.page.seo_title if block_content.page.seo_title.present?
          item["seo_description"] = block_content.page.seo_description if block_content.page.seo_description.present?
          item["seo_keywords"] = block_content.page.seo_keywords if block_content.page.seo_keywords.present?
          item["seo_index_mode"] = block_content.page.seo_index_mode
          item["canonical_url"] = block_content.page.canonical_url if block_content.page.canonical_url.present?
          # Open Graph fields
          item["og_type"] = block_content.page.og_type
          item["og_title"] = block_content.page.og_title if block_content.page.og_title.present?
          item["og_description"] = block_content.page.og_description if block_content.page.og_description.present?
          item["og_image_url"] = active_storage_url(block_content.page.og_image) if block_content.page.og_image.attached?
          # Panda CMS Pro fields (if present)
          item["contributor_count"] = block_content.page.contributor_count if block_content.page.respond_to?(:contributor_count)
          item["workflow_status"] = block_content.page.workflow_status if block_content.page.respond_to?(:workflow_status)
          item["inherit_seo"] = block_content.page.inherit_seo if block_content.page.respond_to?(:inherit_seo)
          item["contents"] ||= {}
          item["contents"][block_content.block.key] = {
            kind: block_content.block.kind, # We need the kind to recreate the block
            content: block_content.content
          }
          data["pages"][block_content.page.path] = item
        end

        # Posts
        Panda::CMS::Post.order("published_at DESC").each do |post|
          post_data = {
            "id" => post.id,
            "slug" => post.slug,
            "title" => post.title,
            "status" => post.status,
            "published_at" => post.published_at&.iso8601,
            "user_email" => post.user&.email,
            "author_email" => post.author&.email,
            "content" => post.content,
            "cached_content" => post.cached_content
          }

          # SEO fields
          post_data["seo_title"] = post.seo_title if post.seo_title.present?
          post_data["seo_description"] = post.seo_description if post.seo_description.present?
          post_data["seo_keywords"] = post.seo_keywords if post.seo_keywords.present?
          post_data["seo_index_mode"] = post.seo_index_mode
          post_data["canonical_url"] = post.canonical_url if post.canonical_url.present?

          # Open Graph fields
          post_data["og_type"] = post.og_type
          post_data["og_title"] = post.og_title if post.og_title.present?
          post_data["og_description"] = post.og_description if post.og_description.present?
          post_data["og_image_url"] = active_storage_url(post.og_image) if post.og_image.attached?

          # Panda CMS Pro fields (if present)
          post_data["contributor_count"] = post.contributor_count if post.respond_to?(:contributor_count)
          post_data["workflow_status"] = post.workflow_status if post.respond_to?(:workflow_status)

          data["posts"] << post_data
        end

        # Menus
        Panda::CMS::Menu.includes(menu_items: :page).order(:name).each do |menu|
          menu_data = {
            "name" => menu.name,
            "kind" => menu.kind
          }

          if menu.kind == "auto" && menu.start_page
            menu_data["start_page_path"] = menu.start_page.path
          elsif menu.kind == "static"
            menu_data["items"] = serialize_menu_items(menu.menu_items)
          end

          data["menus"] << menu_data
        end

        # Templates
        # Skipping templates for now as they are code-based

        data["settings"] = {}

        data.with_indifferent_access
      end

      #
      # Serialize menu items recursively
      #
      # @param menu_items [ActiveRecord::Relation<Panda::CMS::MenuItem>]
      # @return [Array<Hash>]
      # @visibility private
      def self.serialize_menu_items(menu_items)
        menu_items.map do |item|
          {
            "text" => item.text,
            "page_path" => item.page&.path,
            "external_url" => item.external_url
          }.compact
        end
      end

      #
      # Get URL for Active Storage attachment
      #
      # @param attachment [ActiveStorage::Attached::One]
      # @return [String, nil]
      # @visibility private
      def self.active_storage_url(attachment)
        return nil unless attachment.attached?

        if Rails.application.routes.url_helpers.respond_to?(:rails_blob_url)
          Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: false)
        else
          # Fallback: return the key which can be used to reconstruct the URL
          attachment.key
        end
      rescue
        nil
      end
    end
  end
end
