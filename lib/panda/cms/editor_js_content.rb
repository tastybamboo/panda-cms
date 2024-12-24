require "debug"

module Panda::CMS::EditorJsContent
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Callbacks

    before_save :generate_cached_content
  end

  def generate_cached_content
    return if content.nil?

    if content[/"editorJS"/]
      begin
        content = JSON.parse(content)
        self.cached_content = if content.dig("source") == "editorJS"
          Panda::CMS::EditorJs::Renderer.new(content).render
        else
          content.to_s
        end
      rescue
        Rails.logger.error "Failed to parse JSON content: #{content}"
        self.cached_content = content.to_s
      end
    end
  end
end
