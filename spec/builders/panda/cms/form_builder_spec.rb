require "rails_helper"

RSpec.describe Panda::CMS::FormBuilder do
  let(:lookup_context) { ActionView::LookupContext.new(ActionController::Base.view_paths) }
  let(:assigns) { {} }
  let(:controller) { ActionController::Base.new }
  let(:template) { ActionView::Base.new(lookup_context, assigns, controller) }
  let(:object) { double("object") }
  let(:builder) { described_class.new(:object, object, template, {}) }

  describe "#email_field" do
    it "renders an email field with label and container" do
      allow(object).to receive(:email).and_return("test@example.com")
      result = builder.email_field(:email)
      expect(result).to include('type="email"')
      expect(result).to include('class="panda-cms-field-container')
    end
  end

  describe "#datetime_field" do
    it "renders a datetime field with label and container" do
      allow(object).to receive(:published_at).and_return(Time.current)
      result = builder.datetime_field(:published_at)
      expect(result).to include('type="datetime')
      expect(result).to include('class="panda-cms-field-container')
    end
  end

  describe "#time_zone_select" do
    it "renders a time zone select with label and container" do
      allow(object).to receive(:time_zone)
      result = builder.time_zone_select(:time_zone)
      expect(result).to include('class="panda-cms-field-container')
      expect(result).to include("<select")
    end
  end

  describe "#meta_text" do
    it "renders meta text when provided" do
      result = builder.meta_text(meta: "Help text")
      expect(result).to include("Help text")
      expect(result).to include('class="block text-black/60')
    end

    it "returns nil when no meta text provided" do
      expect(builder.meta_text({})).to be_nil
    end
  end

  describe "#button" do
    it "renders a button with default styles" do
      result = builder.button("Save")
      expect(result).to include('type="submit"')
      expect(result).to include('class="inline-flex items-center rounded-md')
      expect(result).to include("fa-circle-check")
    end

    it "renders a button with custom block content" do
      allow(object).to receive(:persisted?).and_return(false)
      allow(object).to receive(:class).and_return(double(name: "TestClass"))
      result = builder.button { "Custom Content" }
      expect(result).to include("Custom Content")
      expect(result).not_to include("fa-circle-check")
    end

    it "handles formmethod option" do
      result = builder.button("Delete", formmethod: "delete")
      expect(result).to include('name="_method"')
      expect(result).to include('value="delete"')
    end
  end
end
