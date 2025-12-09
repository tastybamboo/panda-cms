RSpec.configure do |config|
  # Set up Current attributes and URL configuration after Capybara is ready
  config.before(:each, type: :system) do
    Panda::CMS::Current.page = nil
    Panda::CMS.config.url = Panda::CMS::Current.root

    # Ensure templates have blocks generated if using fixtures
    if defined?(Panda::CMS::Template) && Panda::CMS::Template.respond_to?(:generate_missing_blocks)
      Panda::CMS::Template.generate_missing_blocks
    end
  end
end

# Configure fixture set class name mapping for namespaced models
# This tells Rails which model class to use for each fixture file
module PandaCmsFixtures
  def self.get_class_name(fixture_set_name)
    case fixture_set_name
      # panda_core_users fixtures are not supported - users must be created programmatically
    when "panda_cms_posts" then "Panda::CMS::Post"
    when "panda_cms_pages" then "Panda::CMS::Page"
    when "panda_cms_templates" then "Panda::CMS::Template"
    when "panda_cms_blocks" then "Panda::CMS::Block"
    when "panda_cms_block_contents" then "Panda::CMS::BlockContent"
    when "panda_cms_menus" then "Panda::CMS::Menu"
    when "panda_cms_menu_items" then "Panda::CMS::MenuItem"
    when "panda_cms_forms" then "Panda::CMS::Form"
    end
  end
end

# Override ActiveRecord::FixtureSet to use our mapping
module ActiveRecord
  class FixtureSet
    alias_method :original_model_class, :model_class

    def model_class
      if (klass = PandaCmsFixtures.get_class_name(@name))
        klass.constantize
      else
        original_model_class
      end
    end
  end
end

def wait_for_iframe_load(iframe_id, timeout: 20)
  puts "[Test] Waiting for iframe #{iframe_id} to load..."

  Timeout.timeout(timeout) do
    # Step 1 — Wait for iframe element to exist
    iframe = nil
    begin
      iframe = page.find("iframe##{iframe_id}", wait: timeout)
    rescue Capybara::ElementNotFound
      puts "[Test] Iframe #{iframe_id} not found in DOM"
      return false
    end

    puts "[Test] Iframe element found: id=#{iframe["id"]} src='#{iframe["src"]}'"

    # Step 2 — Wait for iframe `src` to be populated
    Capybara.using_wait_time(2) do
      until iframe["src"] && iframe["src"] != "" && iframe["src"] != "about:blank"
        puts "[Test] Iframe src not ready (#{iframe["src"].inspect})... waiting"
        sleep 0.2
        iframe = page.find("iframe##{iframe_id}") # refresh handle
      end
    end

    puts "[Test] Iframe has non-blank src: #{iframe["src"]}"

    # Step 3 — Switch into frame and wait for DOM load
    page.document.synchronize(timeout) do
      within_frame(iframe_id) do
        ready = begin
          page.evaluate_script("document.readyState")
        rescue
          nil
        end
        url = begin
          page.evaluate_script("window.location.href")
        rescue
          nil
        end

        puts "[Test] Frame readyState=#{ready.inspect}, url=#{url.inspect}"

        # Must have a real URL and full DOM load
        raise "iframe not loaded" unless
          ready == "complete" && url && url != "about:blank"
      end
    rescue => e
      puts "[Test] Frame not ready yet: #{e.class}: #{e.message}"
      sleep 0.2
      raise Capybara::ElementNotFound
    end

    puts "[Test] Iframe #{iframe_id} fully loaded"
    return true
  end
rescue Timeout::Error
  puts "[Test] Timeout while waiting for iframe #{iframe_id}"

  begin
    iframe = page.first("iframe##{iframe_id}")
    if iframe
      puts "[Test] Final iframe debug: src=#{iframe["src"]}"
    else
      puts "[Test] Iframe not present. Existing iframes: #{page.all("iframe").map { |i| i["id"] }}"
    end
  rescue => e
    puts "[Test] Failed to gather iframe debug info: #{e.message}"
  end

  false
end
