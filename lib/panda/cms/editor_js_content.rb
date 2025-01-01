require "json"

module Panda::CMS::EditorJsContent
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Callbacks

    before_save :generate_cached_content
  end

  def generate_cached_content
    if content.is_a?(String)
      self.cached_content = content
    elsif content.is_a?(Hash) && content["blocks"].present?
      # Process EditorJS content
      self.cached_content = Panda::CMS::EditorJs::Renderer.new(content).render
    end
  end
end
