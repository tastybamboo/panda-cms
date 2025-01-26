require "json"

module Panda::CMS::EditorJsContent
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Callbacks

    before_save :generate_cached_content
  end

  def content=(value)
    if value.is_a?(Hash)
      super(value.to_json)
    else
      super
    end
  end

  def content
    value = super
    if value.is_a?(String)
      begin
        JSON.parse(value)
      rescue JSON::ParserError
        value
      end
    else
      value
    end
  end

  def generate_cached_content
    if content.is_a?(String)
      begin
        parsed_content = JSON.parse(content)
        self.cached_content = if parsed_content.is_a?(Hash) && parsed_content["blocks"].present?
          Panda::CMS::EditorJs::Renderer.new(parsed_content).render
        else
          content
        end
      rescue JSON::ParserError
        # If it's not JSON, treat it as plain text
        self.cached_content = content
      end
    elsif content.is_a?(Hash) && content["blocks"].present?
      # Process EditorJS content
      self.cached_content = Panda::CMS::EditorJs::Renderer.new(content).render
    else
      # For any other case, store as is
      self.cached_content = content.to_s
    end
  end
end
