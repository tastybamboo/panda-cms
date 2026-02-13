# frozen_string_literal: true

require 'active_support/core_ext/integer/time'
require 'capybara/rspec'
require 'bullet' if defined?(Bullet)

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!
#
Rails.application.config.after_initialize do
  # Disable Bullet in CI/system specs
  Bullet.enabled = false if defined?(Bullet)
end

Rails.application.configure do
  # Always disable Better Errors in test environment
  ENV['DISABLE_BETTER_ERRORS'] = 'true'

  # Session store is configured in config/initializers/session_store.rb

  config.after_initialize do
    if defined?(Bullet)
      Bullet.enable = true
      Bullet.bullet_logger = true
      Bullet.raise = false # raise an error if n+1 query occurs
    end

    config.middleware.delete ActionDispatch::ShowExceptions rescue nil
    config.middleware.delete ActionDispatch::DebugExceptions rescue nil
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV['CI'].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # In CI we rely on precompiled, fingerprinted assets produced by
  # panda-assets-verify-action. Disable on-the-fly compilation so Propshaft and
  # importmap use the manifest that action generates; keep dynamic compilation
  # enabled locally for fast iteration.
  if ENV["CI"].present?
    if config.respond_to?(:importmap)
      config.importmap.cache_sweepers = []
    end

    config.assets.compile = false
    config.assets.debug = false
    config.assets.digest = true
  else
    config.assets.compile = true
    config.assets.debug = true
  end

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  # Use memory store for tests to support rate limiting tests
  config.cache_store = :memory_store

  # Send logs to STDOUT in CI/containers and keep SQL noise out of the main log.
  base_logger = ActiveSupport::Logger.new($stdout)
  base_logger.level = Logger::INFO
  base_logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(base_logger)
  config.active_record.logger = nil

  # Raise for all exceptions, to fail fast in tests
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Don't print deprecation notices to the stderr.
  config.active_support.deprecation = false

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # Disabled: incompatible with ViewComponent template compilation on Ruby 4.0+
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Configure OmniAuth for testing
  config.after_initialize do
    if defined?(OmniAuth)
      OmniAuth.config.test_mode = true
      OmniAuth.config.on_failure = proc { |env|
        OmniAuth::FailureEndpoint.new(env).redirect_to_failure
      }
    end
  end
end
