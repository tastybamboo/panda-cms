# frozen_string_literal: true

module HtmlHelpers
  def normalize_html(html)
    html.gsub(/\s+/, " ").strip
  end
end

RSpec.configure do |config|
  config.include HtmlHelpers
end
