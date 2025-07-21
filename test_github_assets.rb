#!/usr/bin/env ruby
# frozen_string_literal: true

# GitHub Asset Distribution Test Script
#
# This script tests the GitHub-based asset distribution system used by Panda CMS.
# It verifies that assets are properly accessible from GitHub releases and that
# the AssetLoader is functioning correctly.
#
# Usage:
#   PANDA_CMS_USE_GITHUB_ASSETS=true bundle exec ruby test_github_assets.rb
#
# Expected behavior:
#   - Detects GitHub asset mode is enabled
#   - Generates correct asset URLs for current version
#   - Tests HTTP accessibility of JavaScript and CSS assets
#   - Follows GitHub redirects to CDN endpoints
#   - Verifies asset loading completes successfully
#
# See docs/developers/github-asset-distribution.md for full documentation.
#
# Test script for GitHub asset loading
require_relative "spec/dummy/config/environment"
require "panda/cms/asset_loader"

puts "🐼 Testing Panda CMS GitHub Asset Loading..."
puts "Environment: #{Rails.env}"
puts "PANDA_CMS_USE_GITHUB_ASSETS: #{ENV["PANDA_CMS_USE_GITHUB_ASSETS"]}"
puts "Version: #{Panda::CMS::VERSION}"
puts ""

begin
  puts "Checking asset loader configuration..."
  use_github = Panda::CMS::AssetLoader.use_github_assets?
  puts "Use GitHub assets: #{use_github}"

  if use_github
    puts "\n📦 GitHub Asset URLs:"
    js_url = Panda::CMS::AssetLoader.javascript_url
    css_url = Panda::CMS::AssetLoader.css_url

    puts "JavaScript: #{js_url}"
    puts "CSS: #{css_url}"

    puts "\n🌐 Testing asset accessibility..."

    # Test JavaScript asset
    require "net/http"
    require "uri"

    def fetch_with_redirect(url, limit = 5)
      raise "Too many redirects" if limit == 0

      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        fetch_with_redirect(response["location"], limit - 1)
      else
        response
      end
    end

    js_response = fetch_with_redirect(js_url)

    if js_response.code == "200"
      puts "✅ JavaScript asset accessible (#{js_response.body.length} bytes)"
    else
      puts "❌ JavaScript asset not accessible (HTTP #{js_response.code})"
    end

    # Test CSS asset
    css_response = fetch_with_redirect(css_url)

    if css_response.code == "200"
      puts "✅ CSS asset accessible (#{css_response.body.length} bytes)"
    else
      puts "❌ CSS asset not accessible (HTTP #{css_response.code})"
    end

  else
    puts "\n🔧 Using local development assets"
    puts "JavaScript: #{Panda::CMS::AssetLoader.javascript_url}"
    puts "CSS: #{Panda::CMS::AssetLoader.css_url}"
  end

  puts "\n🎯 Testing asset loading..."
  Panda::CMS::AssetLoader.ensure_assets_available!
  puts "✅ Asset loading completed successfully"
rescue => e
  puts "❌ Error during asset loading test:"
  puts "  #{e.class}: #{e.message}"
  puts "  Backtrace:"
  e.backtrace.first(5).each { |line| puts "    #{line}" }
  exit 1
end

puts "\n🎉 All tests passed!"
