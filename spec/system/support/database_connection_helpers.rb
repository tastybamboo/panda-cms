# frozen_string_literal: true

# Share database connection between test thread and server thread
# This allows the Puma server to see uncommitted transaction data from fixtures
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

# Set up shared connection before system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
  end

  config.after(:each, type: :system) do
    ActiveRecord::Base.shared_connection = nil
  end
end
