# frozen_string_literal: true

# Configure Chartkick for the test environment
# Chartkick is loaded as a dependency of panda-cms
if defined?(Chartkick)
  Chartkick.options = {
    adapter: "chartjs"
  }
end
