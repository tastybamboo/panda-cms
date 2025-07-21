#!/bin/bash
# Script to run only the failing authentication tests for debugging

set -e

echo "Running focused authentication tests..."

# Set CI environment to trigger debug logging
export CI=true

# Run only the specific failing tests
bundle exec rspec \
  spec/system/panda/cms/admin/login_spec.rb:17 \
  spec/system/panda/cms/admin/login_spec.rb:57 \
  --format documentation \
  --color

echo "Authentication tests completed."