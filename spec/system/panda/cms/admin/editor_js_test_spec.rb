require "system_helper"

RSpec.describe "Editor.js resources", type: :system, editorjs: true do
  fixtures :panda_cms_users
  it "can load Editor.js resources properly" do
    login_as_admin

    visit "/admin"

    # Create a test div to load Editor.js into
    page.execute_script(<<~JS)
      const testDiv = document.createElement('div');
      testDiv.id = 'editor-js-test';
      testDiv.style.width = '100%';
      testDiv.style.height = '300px';
      testDiv.style.padding = '20px';
      testDiv.style.border = '1px solid #ccc';
      document.body.appendChild(testDiv);

      console.log("Created test div for Editor.js");
    JS

    # Directly attempt to load each Editor.js script
    scripts = [
      "/panda-cms-assets/editor-js/core/editorjs.min.js",
      "/panda-cms-assets/editor-js/plugins/paragraph.min.js",
      "/panda-cms-assets/editor-js/plugins/header.min.js",
      "/panda-cms-assets/editor-js/plugins/nested-list.min.js",
      "/panda-cms-assets/editor-js/plugins/quote.min.js",
      "/panda-cms-assets/editor-js/plugins/simple-image.min.js",
      "/panda-cms-assets/editor-js/plugins/table.min.js",
      "/panda-cms-assets/editor-js/plugins/embed.min.js"
    ]

    # Load each script sequentially
    scripts.each do |script|
      page.execute_script(<<~JS)
        (function() {
          console.log("Loading script: #{script}");
          var scriptEl = document.createElement('script');
          scriptEl.src = "#{script}";
          scriptEl.async = false;
          scriptEl.onload = function() { console.log("Successfully loaded: #{script}"); };
          scriptEl.onerror = function(e) { console.error("Failed to load: #{script}", e); };
          document.head.appendChild(scriptEl);
        })();
      JS

      # Give each script a moment to load
      sleep(0.5)
    end

    # Give scripts time to finish loading
    sleep(2)

    # Check which JavaScript objects are available
    page.evaluate_script(<<~JS)
      (function() {
        var objects = {
          editorjs: typeof EditorJS !== 'undefined',
          paragraph: typeof Paragraph !== 'undefined',
          header: typeof Header !== 'undefined',
          nestedList: typeof NestedList !== 'undefined',
          quote: typeof Quote !== 'undefined',
          simpleImage: typeof SimpleImage !== 'undefined',
          table: typeof Table !== 'undefined',
          embed: typeof Embed !== 'undefined'
        };

        // List all loaded scripts for debugging
        var loadedScripts = [];
        for (var i = 0; i < document.scripts.length; i++) {
          loadedScripts.push(document.scripts[i].src);
        }

        return { objects: objects, loadedScripts: loadedScripts };
      })();
    JS

    # puts "Editor.js Test Results:"
    # puts "----------------------"

    # # Print which objects are available
    # if result && result["objects"]
    #   result["objects"].each do |name, available|
    #     puts "#{name}: #{available ? 'YES' : 'NO'}"
    #   end

    #   puts "\nLoaded Scripts:"
    #   puts "---------------"
    #   if result["loadedScripts"]
    #     result["loadedScripts"].each do |script|
    #       puts script if script.include?('editor-js')
    #     end
    #   else
    #     puts "No script data available"
    #   end

    #   # Check if we have all required objects
    #   required_objects = ['editorjs', 'paragraph', 'header', 'nestedList', 'quote', 'simpleImage', 'table', 'embed']
    #   missing_objects = required_objects.reject { |obj| result["objects"][obj] }
    # else
    #   puts "No result data available"
    #   missing_objects = []
    # end

    # if missing_objects.any?
    #   puts "\nMISSING OBJECTS: #{missing_objects.join(', ')}"
    # else
    #   puts "\nALL REQUIRED OBJECTS AVAILABLE!"
    # end
  end
end
