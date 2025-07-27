---
layout: default
title: Testing
nav_order: 6
parent: Developers
has_children: true
---

# Testing

This section covers testing practices and patterns for Panda CMS development.

## Overview

Panda CMS uses RSpec for testing with the following structure:

- **Unit Tests**: Model and service object tests
- **System Tests**: Full browser automation tests using Cuprite (Chrome headless)
- **Component Tests**: ViewComponent testing
- **Integration Tests**: Controller and API tests

## Test Structure

- Uses fixtures instead of factories for consistent test data
- Fixtures located in `spec/fixtures/` with YAML format
- System tests use special helper methods to prevent browser resets in CI
- EditorJS tests are excluded by default (use `INCLUDE_EDITORJS=true` to include)

## Key Testing Guides

- [Validation Testing](validation-testing.md) - Essential patterns for form validation tests
- [System Test Helpers](../../TROUBLESHOOTING_JAVASCRIPT.md) - Debugging JavaScript issues in tests

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run tests with focus/exclusions  
bundle exec rspec --tag ~skip

# Run specific test types
bundle exec rspec spec/models/
bundle exec rspec spec/system/
bundle exec rspec spec/lib/

# Include EditorJS tests (excluded by default)
INCLUDE_EDITORJS=true bundle exec rspec
```

## Test Environment

Tests run in the `spec/dummy` Rails application which provides a complete Rails environment for testing the engine.

The dummy app includes:
- Database setup and migrations
- Asset compilation for system tests  
- Authentication configuration
- Sample fixtures and test data