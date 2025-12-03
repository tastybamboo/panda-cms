# frozen_string_literal: true

# =============================================================================
# Panda CMS — Fully Integrated Cuprite Driver + Diagnostics (Final Version)
# =============================================================================

require "ferrum"
require "capybara/cuprite"
require "tmpdir"
require "fileutils"
require "json"

return unless defined?(Capybara)

# =============================================================================
# Ensure writeable-HOME directory (when running from codex/claude)
# =============================================================================

module Panda
  module Core
    module Testing
      # Manage HOME for headless Chrome without permanently mutating it
      module HomeDir
        class << self
          def original_home
            @original_home ||= ENV["HOME"]
          end

          def ensure_writable_home!
            if RUBY_PLATFORM.include?("darwin") || ENV.fetch("HOME", "").empty? || !File.writable?(ENV["HOME"])
              ENV["HOME"] = Dir.mktmpdir("panda-home")
              puts "🐼 HOME forced for headless Chrome → #{ENV["HOME"]}"
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

# In sandboxed runs /Users/xxxxxx is read-only, so ensure Chrome has a writable
# HOME, but restore it after the suite.
Panda::Core::Testing::HomeDir.ensure_writable_home!

# =============================================================================
# Browser options setup
# =============================================================================

module Panda
  module Core
    module Testing
      # Fatal abort helper
      def self.fatal!(msg)
        warn "\n[Cuprite Fatal] #{msg}"
        abort("[Cuprite Fatal] Aborting: Cuprite cannot run reliably.\n")
      end

      # Force kill a running process
      def self.force_kill(pid, timeout: 2)
        return unless pid

        pgid = nil

        begin
          pgid = Process.getpgid(pid)
        rescue Errno::ESRCH
          return
        end

        # 1. TERM the whole process group
        begin
          Process.kill("-TERM", pgid)   # negative PID = process group
        rescue Errno::ESRCH
          return
        end

        deadline = Time.now + timeout

        # 2. Wait for all procs to exit
        loop do
          begin
            Process.kill(0, pid) # still alive?
          rescue Errno::ESRCH
            break # dead
          end

          break if Time.now >= deadline
          sleep 0.1
        end

        # 3. If still alive, KILL the whole group
        begin
          Process.kill("-KILL", pgid)
        rescue Errno::ESRCH
        end

        begin
          Process.wait(pid)
        rescue Errno::ECHILD
        end
      end

      # Allow overriding the Chrome/Chromium binary via env so we can point at a
      # headless-friendly build (e.g. Homebrew Chromium) instead of GUI Chrome.
      def self.browser_path
        return @browser_path if defined?(@browser_path)

        env_path = ENV["PANDA_CHROME_PATH"].to_s
        resolved_path = env_path.empty? ? Panda::Core::Testing::Support::System::ChromePath.resolve : env_path

        unless resolved_path && File.exist?(resolved_path)
          fatal!("Browser path #{resolved_path.inspect} does not exist.")
        end

        puts "🐼 Chrome path: #{resolved_path}"

        @browser_path = resolved_path
      end

      # Faux-const for the macOS unsafe flags: cause Chrome crashes or GUI startup on macOS
      #
      # Set the unsafe flags for macOS at the top level, as we want to remove them
      # whenever we invoke a new Cuprite driver incase we've accidentally added them
      # back
      # TODO: Add this in
      def self.macos_unsafe_chrome_flags
        @macos_unsafe_chrome_flags ||= %w[
          disable-gpu
          disable-dev-shm-usage
          disable-namespace-sandbox
          disable-setuid-sandbox
          disable-software-rasterizer
        ]
      end

      # Faux-const for the default browser options
      def self.default_browser_options
        return @default_browser_options if defined?(@default_browser_options)

        user_data_dir = ENV["HOME"].to_s.empty? ? Dir.mktmpdir("chrome-user-data-dir") : ENV["HOME"]

        options = {
          # Sandbox & GPU
          "no-sandbox" => nil,
          "disable-gpu" => nil,
          "disable-dev-shm-usage" => nil,
          "disable-namespace-sandbox" => nil,
          "disable-setuid-sandbox" => nil,
          "disable-software-rasterizer" => nil,
          # Disable all Google Messaging / Sync / Push subsystems
          "disable-sync" => nil,
          "disable-push-messaging" => nil,
          "disable-notifications" => nil,
          "disable-gcm-service-worker" => nil,
          "disable-default-apps" => nil,
          "disable-domain-reliability" => nil,
          "disable-component-update" => nil,
          "disable-background-networking" => nil,
          "disable-cloud-import" => nil,
          # Avoid first run Chrome setup/default browser check
          "no-first-run" => nil,
          "no-default-browser-check" => nil,
          # Disable extraneous UI subsystems
          "disable-print-preview" => nil,
          "disable-features" => "Translate,MediaRouter,UseOzonePlatform,OptimizationGuideModelDownloading",
          "mute-audio" => nil,
          # Let Cuprite choose a port
          "remote-debugging-port" => 0,
          # Quiet mode (suppresses GCM + proxy resolver + metadata logs)
          "log-level" => "3",
          "v" => "0",
          # Specifically set a random user data directory
          "user-data-dir" => user_data_dir
        }

        if RUBY_PLATFORM.include?("darwin")
          # TODO: Abstract this to a browser options method modified for macOS
          # Remove Linux-only or unstable flags on macOS
          options = options.reject { |k, _| macos_unsafe_chrome_flags.include?(k) }

          # Remove UseOzonePlatform from disable-features
          disable_features = options["disable-features"].split(",")
          disable_features.delete("UseOzonePlatform")
          options["disable-features"] = disable_features.join(",")

          # Chrome.app needs this for headless mode
          options["use-mock-keychain"] = nil
          options["headless"] = "chrome"
        end

        @default_browser_options = options
      end

      # ========================================================================
      # Diagnostics state (shared)
      # ========================================================================
      module CupriteDiagnostics
        class << self
          attr_accessor :last_devtools_command
        end
      end

      # ========================================================================
      # 1. Chrome stderr --> stream to STDOUT
      # ========================================================================
      module ChromeStderr
        def start(*args, **kwargs)
          result = super

          process = instance_variable_get(:@process)
          pid = process&.pid

          # Only Linux supports /proc — skip stderr streaming on macOS
          if pid && RUBY_PLATFORM.include?("linux")
            Thread.new do
              Thread.current.name = "chrome-stderr-#{pid}"
              begin
                File.open("/proc/#{pid}/fd/2", "r") do |stderr|
                  puts "=== [Chrome STDERR Stream PID #{pid}] ==="
                  stderr.each_line { |line| puts "[Chrome STDERR] #{line.chomp}" }
                end
              rescue => e
                warn "[ChromeStderr] STDERR stream failed: #{e.class}: #{e.message}"
              end
            end
          end

          result
        end
      end

      # ========================================================================
      # 2. CDP DevTools recorder (Ferrum 0.17 API)
      # ========================================================================
      module DevtoolsRecorder
        def command(method, params: nil, **kwargs)
          Panda::Core::Testing::CupriteDiagnostics.last_devtools_command = {
            method: method,
            params: params,
            kwargs: kwargs,
            timestamp: Time.now
          }

          super
        end
      end

      # ========================================================================
      # 3. Pretty per-test logging
      # ========================================================================
      module TestLogging
        def self.read_rss
          File.read("/proc/self/status")[/^VmRSS:\s+(\d+)/, 1].to_i
        rescue
          0
        end

        def self.install(config)
          config.before(:example) do |example|
            @__t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            @__rss_before = Panda::Core::Testing::TestLogging.read_rss

            puts "\n[TEST START] (#{example.metadata[:type]}) #{example.full_description}"
            puts "              ↳ #{example.metadata[:file_path]}:#{example.metadata[:line_number]}"
          end

          config.after(:example) do |example|
            duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @__t0
            delta_rss = Panda::Core::Testing::TestLogging.read_rss - @__rss_before
            status = example.exception ? "FAIL" : "PASS"

            puts "[TEST END] #{status} — #{(duration * 1000).round(1)}ms | ΔRSS #{delta_rss} KB"
          end
        end
      end

      # ========================================================================
      # 4. Chrome verification (hard-abort on failure)
      # ========================================================================
      def self.verify_chrome!
        opts = Panda::Core::Testing.default_browser_options.dup
        smoke_test_profile_dir = Dir.mktmpdir("cuprite-smoke")
        opts["user-data-dir"] = smoke_test_profile_dir

        cmd = [Panda::Core::Testing.browser_path]

        opts.each do |flag, value|
          cmd << if value.nil?
            "--#{flag}"
          else
            "--#{flag}=#{value}"
          end
        end

        # Final URL to load
        cmd << "about:blank"

        puts "[Chrome Smoke Test] Launching Chrome..."
        pid = Process.spawn(*cmd, out: File::NULL, err: File::NULL)

        devtools_file = File.join(smoke_test_profile_dir, "DevToolsActivePort")

        # Retry for ~1s (Chrome may take 50–300ms to write the port)
        50.times do
          break if File.exist?(devtools_file)
          sleep 0.02
        end

        fatal!("Chrome smoke test failed — DevToolsActivePort missing") unless File.exist?(devtools_file)

        lines = File.read(devtools_file).split("\n")
        port = lines.first.to_i
        ws_url = "ws://127.0.0.1:#{port}#{lines[1]}"

        puts "🐼 Chrome smoke test WebSocket URL: #{ws_url}"
        puts "🐼 Chrome smoke test OK; PID: #{pid}"
      ensure
        # We don't want a hanging process, kill it at the end
        Panda::Core::Testing.force_kill(pid)
      end

      # ========================================================================
      # 5. Cuprite warmup
      # ========================================================================
      def self.warmup_cuprite!
        warmup_url = "#{Capybara.app_host}/admin/login"
        begin
          session = Capybara::Session.new(:panda_cuprite)
          session.visit(warmup_url)
          status = session.status_code

          fatal!("Warmup GET #{warmup_url} returned #{status}") unless status.between?(200, 399)
          puts "🐼 Warmup OK → #{warmup_url} (#{status})"
        rescue => e
          fatal!("Warmup exception: #{e.class}: #{e.message}")
        end
      end

      # ========================================================================
      # 6. Cuprite smoke tests
      # ========================================================================
      def self.smoke_test_cuprite!
        browser_options = Panda::Core::Testing.default_browser_options
        browser_options["user-data-dir"] = Dir.mktmpdir("chrome-smoke-test")

        browser_path = Panda::Core::Testing.browser_path

        puts "🐼 Browser path at Cuprite init: #{browser_path}"

        # TODO: We use this code in a few places, abstract it out so we can call
        # driver = Panda::Testing::CupriteDriver.new_with_overrides(options: ..., browser_options: ...)

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

        begin
          session.visit("data:text/html,<h1 id='x'>Hello</h1>")

          fatal!("JS eval failed") unless session.evaluate_script("1 + 1") == 2
          fatal!("DOM read failed") unless session.find("#x").text == "Hello"

          puts "🐼 Smoke tests OK"
        rescue => e
          fatal!("Smoke test failed: #{e.class}: #{e.message}")
        end
      end
    end
  end
end

# =============================================================================
# Apply Ferrum patches
# =============================================================================
Ferrum::Browser.prepend(Panda::Core::Testing::ChromeStderr)
Ferrum::Client.prepend(Panda::Core::Testing::DevtoolsRecorder)

# =============================================================================
# Capybara driver registration
# =============================================================================

Capybara.default_max_wait_time = 5
Capybara.server_host = "0.0.0.0"
Capybara.server_port = nil
Capybara.always_include_port = true
Capybara.reuse_server = true
Capybara.raise_server_errors = true

Rails.application.config.action_dispatch.show_exceptions = false
Rails.application.config.consider_all_requests_local = true

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

Capybara.javascript_driver = :panda_cuprite

# =============================================================================
# Boot sequence: Chrome → Server → Warmup → Smoke test
# =============================================================================

RSpec.configure do |config|
  config.append_before(:suite) do
    # 1. Chrome sanity check
    Panda::Core::Testing.verify_chrome!

    # 2. Boot Capybara server
    server = Capybara::Server.new(
      Capybara.app,
      port: nil,
      host: Capybara.server_host
    )
    server.boot

    app_host = "http://#{server.host}:#{server.port}"
    Capybara.app_host = app_host

    puts "🐼 Capybara server running at #{app_host}"

    # 3. Cuprite smoke tests
    Panda::Core::Testing.smoke_test_cuprite!

    # 4. Cuprite warmup
    Panda::Core::Testing.warmup_cuprite!
  end

  config.append_after(:suite) do
    Panda::Core::Testing::HomeDir.restore_home!
  end
end

# =============================================================================
# Failure diagnostics (screenshots + CDP dump)
# =============================================================================

RSpec.configure do |config|
  config.after(:example, type: :system) do |example|
    next unless example.exception

    dir = Rails.root.join("tmp/cuprite_failures")
    FileUtils.mkdir_p(dir)

    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    slug = example.full_description.parameterize

    # Save last CDP command
    if Panda::Core::Testing::CupriteDiagnostics.last_devtools_command
      File.write(
        dir.join("#{slug}_#{timestamp}_last_cdp.json"),
        JSON.pretty_generate(Panda::Core::Testing::CupriteDiagnostics.last_devtools_command)
      )
    end

    begin
      screenshot_path = dir.join("#{slug}_#{timestamp}.png")
      Capybara.page.save_screenshot(screenshot_path, full: true)
      puts "[Failure Diagnostics] Saved screenshot → #{screenshot_path}"
    rescue => e
      warn "[Failure Diagnostics] Screenshot failed: #{e.class}: #{e.message}"
    end

    puts "[Failure Diagnostics] Artifacts saved → #{dir}"
  end
end

# =============================================================================
# Install global test logging
# =============================================================================

RSpec.configure do |config|
  Panda::Core::Testing::TestLogging.install(config)
end
