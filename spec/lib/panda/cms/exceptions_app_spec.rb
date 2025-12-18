# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::ExceptionsApp do
  let(:app) { double("exceptions_app") }
  let(:exceptions_app) { described_class.new(exceptions_app: app) }

  describe "#call" do
    let(:env) { {"CONTENT_TYPE" => "text/html", "REQUEST_METHOD" => "GET"} }
    let(:request) { ActionDispatch::Request.new(env) }

    before do
      allow(ActionDispatch::Request).to receive(:new).with(env).and_return(request)
    end

    it "delegates to the wrapped exceptions_app" do
      expect(app).to receive(:call).with(env)

      exceptions_app.call(env)
    end

    context "when request has invalid MIME type" do
      before do
        allow(request).to receive(:formats).and_raise(
          ActionDispatch::Http::MimeNegotiation::InvalidType
        )
      end

      it "falls back to HTML format" do
        expect(request).to receive(:set_header).with("CONTENT_TYPE", "text/html")
        expect(app).to receive(:call).with(env)

        exceptions_app.call(env)
      end

      it "continues processing the request" do
        allow(request).to receive(:set_header)
        expect(app).to receive(:call).with(env)

        exceptions_app.call(env)
      end
    end

    context "when request has valid MIME type" do
      it "does not modify the request" do
        # Allow set_header to be called (Rails internals), but track calls
        allow(request).to receive(:set_header).and_call_original
        expect(app).to receive(:call).with(env)

        exceptions_app.call(env)

        # Verify CONTENT_TYPE was not modified
        expect(request).not_to have_received(:set_header).with("CONTENT_TYPE", anything)
      end
    end
  end
end
