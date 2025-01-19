require "system_helper"

RSpec.describe "Adding a post", type: :system do
  include EditorHelpers

  before do
    login_as_admin
    visit panda_cms.admin_posts_path
    click_link "Add Post"
    wait_for_editor
  end

  it "creates a new post with EditorJS content and maintains content after update" do
    fill_in "Title", with: "Test Post"
    fill_in "URL", with: "/#{Time.current.strftime("%Y/%m")}/test-post"

    add_editor_header("Test Header")
    add_editor_paragraph("Test content")
    add_editor_list(["Item 1", "Item 2"])
    add_editor_quote("Test quote")

    if ENV["DEBUG"]
      puts "\n=== Debug: Editor State After Adding Quote ==="

      # First check if editor exists and is ready
      editor_exists = page.evaluate_script('typeof window.editor !== "undefined" && window.editor !== null')
      puts "\nEditor exists: #{editor_exists}"

      if editor_exists
        # Check EditorJS internal state
        json_content = page.evaluate_script("window.editor.save()")
        puts "\nEditorJS blocks:"
        puts JSON.pretty_generate(json_content)

        # Check what blocks exist
        block_count = page.evaluate_script("window.editor.blocks.getBlocksCount()")
        puts "\nTotal blocks: #{block_count}"

        # Get all block types
        block_types = page.evaluate_script("window.editor.blocks.getBlockTypes()")
        puts "\nBlock types present:"
        puts block_types.inspect
      end

      # Check the actual content in the editor
      puts "\nVisible content in editor:"
      within(editor_container_id) do
        page.all(".ce-block").each_with_index do |block, i|
          puts "Block #{i + 1}:"
          puts "Text: #{block.text}"
          puts "Classes: #{block["class"]}"
        end
      end

      puts "\n=== End Debug ==="
    end

    click_button "Create Post"

    expect(page).to have_content("The post was successfully created!", wait: 1)
    expect(page).to have_content("Test Post", wait: 1)

    # Find the newly created post
    post = Panda::CMS::Post.find_by!(title: "Test Post")

    expect_editor_content_to_include("Test Header", post)
    expect_editor_content_to_include("Test content", post)
    expect_editor_content_to_include("Item 1", post)
    expect_editor_content_to_include("Test quote", post)
  end

  it "preserves content when validation fails" do
    add_editor_header("Test Header")
    add_editor_paragraph("Test content")
    add_editor_list(["Item 1", "Item 2"])
    add_editor_quote("Test quote")

    debug "\n=== Debug: Content before submission ==="
    json_content = page.evaluate_script("window.editor.save()")
    debug "\nEditorJS content:"
    debug JSON.pretty_generate(json_content)

    hidden_field = page.find("[data-editor-form-target='hiddenField']", visible: false, wait: 1)
    debug "\nHidden field value:"
    debug hidden_field.value

    debug "\nAll contenteditable elements text:"
    page.all("[contenteditable]").each_with_index do |el, i|
      puts "#{i}: #{el.text}"
    end
    puts "=== End Debug ==="

    click_button "Create Post"

    expect(page).to have_content("Title can't be blank", wait: 1)
    expect_editor_content_to_include("Test Header")
    expect_editor_content_to_include("Test content")
    expect_editor_content_to_include("Item 1")
    expect_editor_content_to_include("Test quote")
  end
end
