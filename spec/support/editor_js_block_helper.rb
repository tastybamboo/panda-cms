module EditorJsHelper
  # Helper method to normalize HTML for comparison, shared with system specs
  def normalize_html(html)
    html.gsub(/\s+/, " ").gsub("> <", "><").strip
  end
end

RSpec.configure do |config|
  config.include EditorJsHelper, type: :model
end
