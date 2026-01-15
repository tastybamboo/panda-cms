# frozen_string_literal: true

module Panda
  module CMS
    # Represents a template in the Panda CMS application.
    class Template < ApplicationRecord
      self.table_name = "panda_cms_templates"

      # Associations
      has_many :pages, class_name: "Panda::CMS::Page", dependent: :restrict_with_error, inverse_of: :template,
        foreign_key: :panda_cms_template_id
      has_many :blocks, class_name: "Panda::CMS::Block", dependent: :restrict_with_error, inverse_of: :template,
        foreign_key: :panda_cms_template_id
      has_many :block_contents, through: :blocks

      # Validations
      validates :name, presence: true, uniqueness: true

      validates :file_path,
        presence: true,
        uniqueness: true,
        format: {with: %r{\Alayouts/.*\z}, message: "must be a valid layout file path"}

      validate :validate_template_file_exists

      # Scopes
      scope :available, lambda {
        where("max_uses IS NULL OR (max_uses > 0 AND pages_count < max_uses)")
      }

      def self.default
        find_by(file_path: "layouts/page")
      end

      def self.reset_counter_cache
        find_each { |template| template.update_column(:pages_count, template.pages.count) }
      end

      # Generate missing blocks for all templates
      # @return [void]
      def self.generate_missing_blocks
        # Loop through all templates in app/views/layouts/*.html.erb
        # Use Rails.root to ensure we scan the correct directory regardless of working directory
        Dir.glob(Rails.root.join("app", "views", "layouts", "*.html.erb")).each do |file|
          # TODO: Delete all blocks which aren't in use by a template?

          File.open(file).each_line do |line|
            # Matches:
            # Panda::CMS::RichTextComponent.new(key: :value)
            # Panda::CMS::RichTextComponent.new key: :value, key: value
            line.match(/Panda::CMS::([a-zA-Z]+)Component\.new[ (]+([^)]+)\)*/) do |match|
              # Extract the template path relative to app/views
              # Handle both absolute and relative paths by extracting from "app/views/" onwards
              template_path = file.to_s.sub(/.*app\/views\//, "").gsub(".html.erb", "")
              template_name = template_path.gsub("layouts/", "").titleize

              # Create the template if it doesn't exist
              template = Panda::CMS::Template.find_or_create_by!(file_path: template_path) do |template|
                template.name = template_name
              end

              next if match[1] == "PageMenu" # Skip PageMenu blocks
              next if match[1] == "Menu" # Skip Menu blocks

              # Previously used match[1].underscore but this supports more complex database
              # operations, and is more secure as it'll force the usage of a class
              block_kind = "Panda::CMS::#{match[1]}Component".constantize::KIND

              match[2].split(",").map do |keyvar|
                key, value = keyvar.split(":", 2)
                next if key != "key"

                block_name = value.to_s.strip.tr(":", "")
                # Create the block if it doesn't exist
                # TODO: +/- the output if it's created or removed
                begin
                  block = Panda::CMS::Block.find_or_create_by!(template: template, kind: block_kind,
                    key: block_name) do |block|
                    block.name = block_name.titleize
                  end
                rescue ActiveRecord::RecordInvalid => e
                  raise "Error creating block '#{block_name}' on template '#{template_name}': #{e.message}"
                end

                # For the given block, create the block_content for each page using the template
                template.pages.each do |page|
                  Panda::CMS::BlockContent.find_or_create_by!(block: block, page: page) do |block_content|
                    block_content.content = {}
                  end
                end
              end
            end
          end
        end
      end

      private

      # Custom validation method to check if the file_path is a valid layout file path
      # NB: Currently only supports .html.erb templates, may want to expand in future?
      # @return [void]
      def validate_template_file_exists
        # Remove any directory traversal attempts from the file_path
        safe_file_path = file_path.to_s.gsub("../", "")
        # Check if the file_path is an ERB template that exists in app/views
        template_path = Rails.root.join("app", "views", "#{safe_file_path}.html.erb")
        # NB: file? checks for files and excludes directories (unlike exist?)
        errors.add(:file_path, "must be an existing layout file path") unless File.file?(template_path)
      end

      # Import templates from the filesystem into the database
      # @return [void]
      def self.load_from_filesystem
        Rails.root.glob("app/views/layouts/**/*.html.erb").each do |file|
          # Extract the file path from the Rails root
          file_path = file.to_s.sub("#{Rails.root}/app/views/", "").sub(".html.erb", "")

          next if ["layouts/application", "layouts/mailer"].include?(file_path)

          # Find or create the template based on the file path
          find_or_create_by(file_path: file_path) do |t|
            t.name = file_path.sub("layouts/", "").titleize
          end
        end
      end

      private_class_method :load_from_filesystem
    end
  end
end
