# frozen_string_literal: true

# Increase wait time for CI environments where asset loading is slower
Capybara.default_max_wait_time = ENV['CI'].present? ? 10 : 5

# Normalize whitespaces when using `has_text?` and similar matchers,
# i.e., ignore newlines, trailing spaces, etc.
# That makes tests less dependent on slightly UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

# Disable animation so we're not waiting for it
Capybara.disable_animation = true

# See BetterRailsSystemTests#take_screenshot
Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &block)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)

Capybara.server_host = "127.0.0.1"
# Let Capybara choose an available port automatically

Panda::CMS.config.url = Capybara.app_host
Rails.application.routes.default_url_options[:host] = Capybara.app_host

RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception
      timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
      "tmp/capybara/failures/#{example.full_description.parameterize}_#{timestamp}"

      # save_page("#{filename_base}.html")
      # save_screenshot("#{filename_base}.png", full: true)
    end
  end
end
