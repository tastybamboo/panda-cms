# File: panda-cms/spec/system/support/shared_browser_session.rb
module SharedBrowserSession
  def self.included(base)
    base.before(:all) do
      @__initial_driver = Capybara.current_driver
      Capybara.current_driver = :better_cuprite
    end

    base.after(:each) do
      # Just reset the session, don't restart browser
      Capybara.reset_sessions!
    end

    base.after(:all) do
      Capybara.current_driver = @__initial_driver
    end
  end
end

RSpec.configure do |config|
  config.include SharedBrowserSession, type: :system
end
