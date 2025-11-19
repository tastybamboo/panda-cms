# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Smoke test", type: :system do
  it "can start the browser and load a page" do
    visit "/"
    expect(page).to have_http_status(:ok)
  end
end
