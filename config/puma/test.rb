# frozen_string_literal: true

# Puma configuration for test environment
workers 0
threads 1, 1

port ENV.fetch("PORT", 3001)
environment "test"

# Allow for proper shutdown
plugin :tmp_restart
