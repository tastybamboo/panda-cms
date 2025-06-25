# frozen_string_literal: true

require "htmlentities"
require "json"

module Panda
  module CMS
    #
    # Bulk editor for site content in JSON format
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
                template: Panda::CMS::Template.find_by(name: page_data["template"]),
                parent: Panda::CMS::Page.find_by(path: page_data["parent"])
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

            if page_data["title"] != current_data["pages"][path]["title"]
              page.update(title: page_data["title"])
              debug[:success] << "Updated: page '#{path}' title from '#{current_data["pages"][path]["title"]}' to '#{page_data["title"]}'"
            end

            if page_data["template"] != current_data["pages"][path]["template"]
              # TODO: Handle page template changes
              debug[:error] << "Page '#{path}' template is '#{current_data["pages"][path]["template"]}' and cannot be changed to '#{page_data["template"]}' without manual intervention"
            end
          end

          page_data["contents"].each do |key, block_data|
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

        new_data["menus"].each do |menu_data|
        end

        new_data["templates"].each do |template_data|
        end

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
          "menus" => {},
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
          item = data["pages"][block_content.page.path] ||= {}
          item["title"] = block_content.page.title
          item["template"] = block_content.page.template.name
          item["parent"] = block_content.page.parent&.path
          item["contents"] ||= {}
          item["contents"][block_content.block.key] = {
            kind: block_content.block.kind, # We need the kind to recreate the block
            content: block_content.content
          }
          data["pages"][block_content.page.path] = item
        end

        # Menus
        # item = data["menus"][] ||= {}

        # Templates
        # item = data["templates"][] ||= {}

        data["settings"] = {}

        data.with_indifferent_access
      end
    end
  end
end
