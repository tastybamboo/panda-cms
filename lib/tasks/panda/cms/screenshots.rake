# frozen_string_literal: true

namespace :panda do
  namespace :cms do
    namespace :screenshots do
      desc "Capture screenshots of The Panda Sanctuary demo site for marketing"
      task capture: [:environment] do
        require "capybara"
        require "capybara/cuprite"

        # Configure Capybara
        Capybara.register_driver :cuprite_screenshots do |app|
          Capybara::Cuprite::Driver.new(
            app,
            window_size: [1920, 1080],
            browser_options: {"no-sandbox" => nil},
            headless: true
          )
        end

        Capybara.default_driver = :cuprite_screenshots
        Capybara.app_host = ENV.fetch("APP_HOST", "http://localhost:3000")

        output_dir = Rails.root.join("tmp", "screenshots", "demo")
        FileUtils.mkdir_p(output_dir)

        puts "Capturing demo site screenshots..."
        puts "Output directory: #{output_dir}"
        puts ""

        session = Capybara::Session.new(:cuprite_screenshots)

        screenshots = [
          {path: "/", name: "homepage", description: "Homepage"},
          {path: "/our-pandas", name: "our-pandas", description: "Our Pandas Gallery"},
          {path: "/about", name: "about", description: "About Page"},
          {path: "/about/contact", name: "contact", description: "Contact Page"},
          {path: "/visit", name: "visit", description: "Visit Information"},
          {path: "/conservation", name: "conservation", description: "Conservation"},
          {path: "/adopt", name: "adopt", description: "Adopt a Panda"},
          {path: "/news", name: "news", description: "News & Updates"},
          {path: "/admin", name: "admin-dashboard", description: "Admin Dashboard"},
          {path: "/admin/pages", name: "admin-pages", description: "Admin Pages"},
          {path: "/admin/posts", name: "admin-posts", description: "Admin Posts"},
          {path: "/admin/forms", name: "admin-forms", description: "Admin Forms"},
          {path: "/admin/menus", name: "admin-menus", description: "Admin Menus"},
          {path: "/admin/files", name: "admin-files", description: "Admin Files"}
        ]

        screenshots.each do |screenshot|
          print "  Capturing #{screenshot[:description]}... "
          session.visit(screenshot[:path])
          sleep 1 # Allow JS to load

          filename = "#{screenshot[:name]}.png"
          filepath = output_dir.join(filename)
          session.save_screenshot(filepath)

          puts "Done (#{filepath})"
        rescue => e
          puts "Failed: #{e.message}"
        end

        # Mobile screenshots
        puts ""
        puts "Capturing mobile screenshots (375x812)..."

        session.driver.resize(375, 812)

        mobile_screenshots = [
          {path: "/", name: "homepage-mobile", description: "Homepage (Mobile)"},
          {path: "/our-pandas", name: "our-pandas-mobile", description: "Our Pandas (Mobile)"},
          {path: "/about/contact", name: "contact-mobile", description: "Contact (Mobile)"}
        ]

        mobile_screenshots.each do |screenshot|
          print "  Capturing #{screenshot[:description]}... "
          session.visit(screenshot[:path])
          sleep 1

          filename = "#{screenshot[:name]}.png"
          filepath = output_dir.join(filename)
          session.save_screenshot(filepath)

          puts "Done (#{filepath})"
        rescue => e
          puts "Failed: #{e.message}"
        end

        session.quit
        puts ""
        puts "Screenshots saved to: #{output_dir}"
        puts "Total: #{screenshots.count + mobile_screenshots.count} screenshots"
      end

      desc "Capture a single screenshot of a given path"
      task :single, [:path, :name] => [:environment] do |_t, args|
        path = args[:path] || "/"
        name = args[:name] || "screenshot"

        require "capybara"
        require "capybara/cuprite"

        Capybara.register_driver :cuprite_single do |app|
          Capybara::Cuprite::Driver.new(
            app,
            window_size: [1920, 1080],
            browser_options: {"no-sandbox" => nil},
            headless: true
          )
        end

        Capybara.default_driver = :cuprite_single
        Capybara.app_host = ENV.fetch("APP_HOST", "http://localhost:3000")

        output_dir = Rails.root.join("tmp", "screenshots")
        FileUtils.mkdir_p(output_dir)

        session = Capybara::Session.new(:cuprite_single)
        session.visit(path)
        sleep 1

        filepath = output_dir.join("#{name}.png")
        session.save_screenshot(filepath)
        session.quit

        puts "Screenshot saved: #{filepath}"
      end
    end
  end
end
