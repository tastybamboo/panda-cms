# frozen_string_literal: true

module Panda
  module CMS
    class FormField < ApplicationRecord
      FIELD_TYPES = %w[text email phone url textarea select checkbox radio file hidden date number signature].freeze

      self.table_name = "panda_cms_form_fields"

      belongs_to :form, class_name: "Panda::CMS::Form"

      validates :name, presence: true,
        format: {with: /\A[a-z_][a-z0-9_]*\z/, message: "must be lowercase with underscores only"}
      validates :name, uniqueness: {scope: :form_id}
      validates :label, presence: true
      validates :field_type, presence: true, inclusion: {in: FIELD_TYPES}

      scope :active, -> { where(active: true) }
      scope :ordered, -> { order(:position) }

      # Parse options JSON for select/radio/checkbox fields
      # @return [Array<String>] List of options
      def options_list
        return [] if options.blank?
        JSON.parse(options)
      rescue JSON::ParserError
        []
      end

      # Set options from array
      # @param opts [Array<String>, String] Options to set
      def options_list=(opts)
        self.options = opts.is_a?(Array) ? opts.to_json : opts
      end

      # Parse validation rules JSON
      # @return [Hash] Validation rules
      def validation_rules
        return {} if validations.blank?
        JSON.parse(validations).symbolize_keys
      rescue JSON::ParserError
        {}
      end

      # Set validation rules from hash
      # @param rules [Hash, String] Validation rules to set
      def validation_rules=(rules)
        self.validations = rules.is_a?(Hash) ? rules.to_json : rules
      end

      # Check if field accepts file uploads
      # @return [Boolean]
      def file_upload?
        field_type == "file"
      end

      # Check if field contains a signature
      # @return [Boolean]
      def signature?
        field_type == "signature"
      end

      # Check if field has multiple options (select, radio, checkbox)
      # @return [Boolean]
      def has_options?
        %w[select radio checkbox].include?(field_type)
      end
    end
  end
end
