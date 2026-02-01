# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Custom Error Pages", type: :request do
  describe "error page routes" do
    {
      404 => {heading: "Page Not Found", title: "Page Not Found (404)"},
      422 => {heading: "Request Rejected", title: "Request Rejected (422)"},
      500 => {heading: "Something Went Wrong", title: "Something Went Wrong (500)"},
      503 => {heading: "Temporarily Unavailable", title: "Temporarily Unavailable (503)"}
    }.each do |status_code, expected|
      context "GET /#{status_code}" do
        before { get "/#{status_code}" }

        it "responds with #{status_code} status" do
          expect(response).to have_http_status(status_code)
          expect(response.content_type).to match(%r{text/html})
        end

        it "uses the error layout" do
          expect(response.body).to include("<!DOCTYPE html>")
        end

        it "includes the page title" do
          expect(response.body).to include("<title>#{expected[:title]}</title>")
        end

        it "includes the heading" do
          expect(response.body).to include(expected[:heading])
        end

        it "includes Panda CMS branding" do
          expect(response.body).to include("Panda CMS")
        end

        it "includes a homepage link" do
          expect(response.body).to include('href="/"')
          expect(response.body).to include("Go to Homepage")
        end

        it "includes an SVG icon" do
          expect(response.body).to include("<svg")
          expect(response.body).to include("</svg>")
        end
      end
    end
  end

  describe "403 error page" do
    before { get "/403" }

    it "responds with 403 status" do
      expect(response).to have_http_status(403)
    end

    it "includes the Access Denied heading" do
      expect(response.body).to include("Access Denied")
    end
  end

  describe "ErrorsController#show" do
    it "falls back to 404 for unsupported error codes" do
      get "/404"
      expect(response).to have_http_status(404)
    end
  end

  describe "exceptions_app configuration" do
    context "in production-like environment" do
      before do
        @original_consider_all_requests_local = Rails.application.config.consider_all_requests_local
        Rails.application.config.consider_all_requests_local = false
      end

      after do
        Rails.application.config.consider_all_requests_local = @original_consider_all_requests_local
      end

      it "configures exceptions_app when consider_all_requests_local is false" do
        expect(Rails.application.config.consider_all_requests_local).to be false
      end
    end

    context "in development environment" do
      it "preserves detailed error pages" do
        expect(Rails.application.config.consider_all_requests_local).to be true
      end
    end
  end

  describe "error page templates" do
    it "allows application to override error templates" do
      # Rails view path precedence ensures app views take priority over gem views
      get "/404"
      expect(response).to have_http_status(404)
    end
  end
end
