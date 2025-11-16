# frozen_string_literal: true

require "system_helper"

RSpec.describe "Menu Form Controller Debug", type: :system do
  fixtures :all

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  it "checks if controller is connected" do
    visit "/admin/cms/menus/new"

    # Wait for page load
    expect(page).to have_css("form", wait: 5)

    # Check if form has controller attribute
    has_controller_attr = page.has_css?('form[data-controller*="menu-form"]')
    puts "\n=== CONTROLLER DEBUG ==="
    puts "Form has menu-form controller: #{has_controller_attr}"

    # Try to get Stimulus controller
    result = page.evaluate_script("(function() { const form = document.querySelector('[data-controller=\"menu-form\"]'); if (!form) return 'form_not_found'; const stimulus = window.Stimulus; if (!stimulus) return 'stimulus_not_found'; try { const controller = stimulus.getControllerForElementAndIdentifier(form, 'menu-form'); return controller ? 'controller_connected' : 'controller_not_connected'; } catch(e) { return 'error: ' + e.message; } })()")

    puts "Stimulus controller status: #{result}"
    puts "======================="

    expect(result).to eq("controller_connected")
  end
end
