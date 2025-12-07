# frozen_string_literal: true

# =============================================================================
# Panda CMS — Fully Integrated Cuprite Driver + Diagnostics
# =============================================================================

require "ferrum"
require "capybara/cuprite"
require "tmpdir"
require "fileutils"
require "json"

return unless defined?(Capybara)

# =============================================================================
# HOME override (macOS sandboxed environments)
# =============================================================================

module Panda
  module Core
    module Testing
      module HomeDir
        class << self
          def original_home
            @original_home ||= ENV["HOME"]
          end

          def ensure_writable_home!
            home = ENV["HOME"].to_s

            if home.empty? || ENV["CI"] || !File.writable?(home)
              new_home =
                if ENV["CI"]
                  Dir.mktmpdir("panda-home", "/tmp")
                else
                  Dir.mktmpdir("panda-home")
                end

              ENV["HOME"] = new_home
              puts "🐼 HOME overridden → #{new_home}"
            end
          end

          def restore_home!
            return unless original_home
            ENV["HOME"] = original_home
          end
        end
      end
    end
  end
end

Panda::Core::Testing::HomeDir.ensure_writable_home!

# =============================================================================
# Browser Resolution (Chrome.app → chromium → google-chrome → fallback)
# =============================================================================

module Panda
  module Core
    module Testing
      def self.fatal!(msg)
        warn "\n[Cuprite Fatal] #{msg}"
        abort("[Cuprite Fatal] Aborting: Cuprite cannot run reliably.\n")
      end

      #
      # Prefer Chrome.app if available
      #
      def self.resolve_chrome_app
        mac_paths = [
          "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
          "#{ENV["HOME"]}/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        ]

        mac_paths.find { |p| File.exist?(p) }
      end

      #
      # Resolve browser_path
      #
      def self.browser_path
        return @browser_path if defined?(@browser_path)

        if ENV["PANDA_CHROME_PATH"] && !ENV["PANDA_CHROME_PATH"].empty?
          candidate = ENV["PANDA_CHROME_PATH"]
          fatal!("Browser path #{candidate.inspect} does not exist.") unless File.exist?(candidate)
          puts "🐼 Chrome path (env): #{candidate}"
          return @browser_path = candidate
        end

        # macOS: prefer Chrome.app
        if RUBY_PLATFORM.include?("darwin")
          app = resolve_chrome_app
          if app
            puts "🐼 Chrome path (Chrome.app): #{app}"
            return @browser_path = app
          end
        end

        # Fallbacks
        fallbacks = %w[
          /usr/bin/google-chrome
          /usr/bin/chromium
          /usr/bin/chromium-browser
          /opt/homebrew/bin/chromium
        ]

        found = fallbacks.find { |p| File.exist?(p) }

        fatal!("No Chrome/Chromium browser found") unless found

        puts "🐼 Chrome path (fallback): #{found}"
        @browser_path = found
      end

      # =============================================================================
      # Default Browser Options (clean, Chrome.app-safe)
      # =============================================================================

      def self.default_browser_options
        return @default_browser_options if defined?(@default_browser_options)

        user_data_dir =
          if ENV["CI"]
            Dir.mktmpdir("chrome-ci-profile", "/tmp")
          else
            Dir.mktmpdir("chrome-profile")
          end

        opts = {
          "no-sandbox" => nil,
          "disable-sync" => nil,
          "disable-push-messaging" => nil,
          "disable-notifications" => nil,
          "disable-gcm-service-worker" => nil,
          "disable-default-apps" => nil,
          "disable-domain-reliability" => nil,
          "disable-component-update" => nil,
          "disable-background-networking" => nil,
          "disable-cloud-import" => nil,
          "no-first-run" => nil,
          "no-default-browser-check" => nil,

          # proper, minimal headless flags
          "headless" => "new",

          # Networking + CDP
          "remote-debugging-port" => 0,

          # Noise reduction
          "log-level" => "3",
          "v" => "0",

          # Profiles
          "user-data-dir" => user_data_dir,

          # Features cleanup
          "disable-features" => "Translate,MediaRouter,OptimizationGuideModelDownloading",

          # no audio device needed
          "mute-audio" => nil
        }

        @default_browser_options = opts
      end

      # =============================================================================
      # Chrome Smoke Test (deterministic, minimal, Chrome.app safe)
      # =============================================================================

      def self.verify_chrome!
        opts = default_browser_options.dup
        tmpdir = Dir.mktmpdir("cuprite-verify")
        opts["user-data-dir"] = tmpdir

        cmd = [browser_path]

        opts.each do |k, v|
          cmd << if v.nil?
            "--#{k}"
          else
            "--#{k}=#{v}"
          end
        end

        cmd << "about:blank"

        puts "[Chrome Smoke Test] Launching Chrome..."
        puts "[Chrome Smoke Test] CMD: #{cmd.inspect}"

        pid = Process.spawn(*cmd, out: File::NULL, err: File::NULL)

        devtools_file = File.join(tmpdir, "DevToolsActivePort")

        50.times do
          break if File.exist?(devtools_file)
          sleep 0.02
        end

        fatal!("Chrome smoke test failed — DevToolsActivePort missing") unless File.exist?(devtools_file)

        lines = File.read(devtools_file).split("\n")
        ws_url = "ws://127.0.0.1:#{lines.first}#{lines[1]}"

        puts "[Chrome Smoke Test] WebSocket URL: #{ws_url}"
        puts "[Chrome Smoke Test] OK"
      ensure
        begin
          Process.kill("TERM", pid) if pid
        rescue
        end
      end

      # =============================================================================
      # Cuprite Smoke Test (unchanged logic)
      # =============================================================================

      def self.smoke_test_cuprite!
        browser_options = default_browser_options.dup
        browser_options["user-data-dir"] = Dir.mktmpdir("chrome-smoke")

        Capybara.register_driver(:panda_cuprite_smoke) do |app|
          Capybara::Cuprite::Driver.new(
            app,
            browser_path: browser_path,
            headless: true,
            timeout: 10,
            process_timeout: 10,
            window_size: [1200, 800],
            browser_options: browser_options
          )
        end

        session = Capybara::Session.new(:panda_cuprite_smoke)

        session.visit("data:text/html,<h1 id='x'>Hello</h1>")

        fatal!("JS eval failed") unless session.evaluate_script("1 + 1") == 2
        fatal!("DOM read failed") unless session.find("#x").text == "Hello"

        puts "🐼 Cuprite smoke tests OK"
      rescue => e
        fatal!("Smoke test failed: #{e.class}: #{e.message}")
      end

      # =============================================================================
      # Warmup (left untouched exactly as requested)
      # =============================================================================

      def self.warmup_cuprite!
        warmup_url = "#{Capybara.app_host}/admin/login"
        session = Capybara::Session.new(:panda_cuprite)
        session.visit(warmup_url)
        status = session.status_code

        fatal!("Warmup GET #{warmup_url} returned #{status}") unless status.between?(200, 399)
        puts "🐼 Warmup OK → #{warmup_url} (#{status})"
      rescue => e
        fatal!("Warmup exception: #{e.class}: #{e.message}")
      end
    end
  end
end

# =============================================================================
# Apply Ferrum patches (unchanged)
# =============================================================================

module Panda
  module Core
    module Testing
      module DevtoolsRecorder
        def command(method, params: nil, **kwargs)
          super
        end
      end
    end
  end
end

Ferrum::Client.prepend(Panda::Core::Testing::DevtoolsRecorder)

# =============================================================================
# Capybara Driver Registration
# =============================================================================

Capybara.default_max_wait_time = 5
Capybara.server_host = "0.0.0.0"
Capybara.always_include_port = true
Capybara.reuse_server = true
Capybara.raise_server_errors = true

Capybara.register_driver(:panda_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    browser_path: Panda::Core::Testing.browser_path,
    headless: true,
    timeout: 30,
    process_timeout: 30,
    js_errors: true,
    window_size: [1200, 800],
    browser_options: Panda::Core::Testing.default_browser_options
  )
end

Capybara.default_driver = :panda_cuprite
Capybara.javascript_driver = :panda_cuprite

# =============================================================================
# Boot Sequence (Chrome → Server → Cuprite Smoke Test → Warmup)
# =============================================================================

RSpec.configure do |config|
  config.append_before(:suite) do
    Panda::Core::Testing.verify_chrome!

    server = Capybara::Server.new(Capybara.app, port: nil, host: Capybara.server_host)
    server.boot

    Capybara.app_host = "http://#{server.host}:#{server.port}"
    puts "🐼 Capybara server running at #{Capybara.app_host}"

    Panda::Core::Testing.smoke_test_cuprite!
    Panda::Core::Testing.warmup_cuprite!
  end

  config.append_after(:suite) do
    Panda::Core::Testing::HomeDir.restore_home!
  end
end
