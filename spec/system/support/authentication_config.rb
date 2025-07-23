# frozen_string_literal: true

# Configure authentication providers for all system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    Panda::CMS.configure do |config|
      config.authentication = {
        google: {enabled: true},
        microsoft: {enabled: true},
        github: {enabled: true}
      }
    end
  end
end
