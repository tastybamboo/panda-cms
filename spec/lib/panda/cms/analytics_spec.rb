# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Analytics do
  before do
    @original_providers = described_class.providers.dup
    described_class.reset!
  end

  after do
    described_class.instance_variable_set(:@providers, @original_providers)
    described_class.reset!
  end

  describe ".providers" do
    it "includes local provider by default" do
      expect(described_class.providers).to include(local: Panda::CMS::Analytics::LocalProvider)
    end
  end

  describe ".register_provider" do
    it "registers a new provider" do
      mock_provider = Class.new(Panda::CMS::Analytics::Provider)

      described_class.register_provider(:test, mock_provider)

      expect(described_class.providers[:test]).to eq(mock_provider)
    end

    it "raises error if provider does not inherit from Provider" do
      expect {
        described_class.register_provider(:invalid, Class.new)
      }.to raise_error(ArgumentError, /must inherit from/)
    end
  end

  describe ".provider" do
    it "returns local provider by default" do
      expect(described_class.provider).to be_a(Panda::CMS::Analytics::LocalProvider)
    end

    it "returns configured provider" do
      described_class.current_provider_name = :local

      expect(described_class.provider).to be_a(Panda::CMS::Analytics::LocalProvider)
    end
  end

  describe ".available?" do
    it "returns true when provider is configured" do
      expect(described_class.available?).to be true
    end
  end

  describe ".configure" do
    it "yields self for configuration" do
      described_class.configure do |config|
        config.current_provider_name = :local
        config.provider_config = {test: true}
      end

      expect(described_class.current_provider_name).to eq(:local)
      expect(described_class.provider_config).to eq({test: true})
    end
  end

  describe ".tracking_providers" do
    it "returns empty by default (LocalProvider does not track)" do
      expect(described_class.tracking_providers).to be_empty
    end

    it "returns providers that support tracking and are configured" do
      tracking_provider = Class.new(Panda::CMS::Analytics::Provider) do
        def configured? = true
        def supports_tracking? = true
        def tracking_configured? = true
        def tracking_script(**) = "<script>test</script>".html_safe
      end

      described_class.register_provider(:test_tracking, tracking_provider)
      allow(Panda::CMS.config).to receive(:analytics).and_return({test_tracking: {enabled: true}})
      described_class.reset!

      expect(described_class.tracking_providers).not_to be_empty
      expect(described_class.tracking_providers.first).to be_a(tracking_provider)
    end

    it "excludes providers that support tracking but are not configured" do
      unconfigured_provider = Class.new(Panda::CMS::Analytics::Provider) do
        def configured? = false
        def supports_tracking? = true
        def tracking_configured? = false
      end

      described_class.register_provider(:unconfigured, unconfigured_provider)
      described_class.reset!

      tracking = described_class.tracking_providers.select { |p| p.is_a?(unconfigured_provider) }
      expect(tracking).to be_empty
    end

    it "is cleared on reset!" do
      described_class.tracking_providers # warm the cache
      described_class.reset!
      # After reset, should rebuild (still empty for default providers)
      expect(described_class.tracking_providers).to be_empty
    end
  end

  describe ".settings_providers" do
    it "returns empty by default" do
      expect(described_class.settings_providers).to be_empty
    end

    it "returns providers with settings pages" do
      settings_provider = Class.new(Panda::CMS::Analytics::Provider) do
        def self.has_settings_page? = true
        def configured? = true
      end

      described_class.register_provider(:with_settings, settings_provider)

      expect(described_class.settings_providers).to include(settings_provider)
    end
  end
end
