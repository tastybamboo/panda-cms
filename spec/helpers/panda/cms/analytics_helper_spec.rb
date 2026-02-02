# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::AnalyticsHelper, type: :helper do
  before do
    @original_providers = Panda::CMS::Analytics.providers.dup
    Panda::CMS::Analytics.reset!
  end

  after do
    Panda::CMS::Analytics.instance_variable_set(:@providers, @original_providers)
    Panda::CMS::Analytics.reset!
  end

  describe "#panda_analytics" do
    context "when no tracking providers are configured" do
      it "returns nil" do
        expect(helper.panda_analytics).to be_nil
      end
    end

    context "when tracking providers are configured" do
      let(:tracking_provider) do
        Class.new(Panda::CMS::Analytics::Provider) do
          def configured? = true
          def supports_tracking? = true
          def tracking_configured? = true

          def tracking_script(**)
            "<script>track();</script>".html_safe
          end
        end
      end

      before do
        Panda::CMS::Analytics.register_provider(:test_tracking, tracking_provider)
        allow(Panda::CMS.config).to receive(:analytics).and_return({test_tracking: {enabled: true}})
        Panda::CMS::Analytics.reset!
      end

      it "returns the combined script tags" do
        result = helper.panda_analytics
        expect(result).to include("<script>track();</script>")
        expect(result).to be_html_safe
      end
    end

    context "with multiple tracking providers" do
      let(:provider_a) do
        Class.new(Panda::CMS::Analytics::Provider) do
          def configured? = true
          def supports_tracking? = true
          def tracking_configured? = true
          def tracking_script(**) = "<script>providerA();</script>".html_safe
        end
      end

      let(:provider_b) do
        Class.new(Panda::CMS::Analytics::Provider) do
          def configured? = true
          def supports_tracking? = true
          def tracking_configured? = true
          def tracking_script(**) = "<script>providerB();</script>".html_safe
        end
      end

      before do
        Panda::CMS::Analytics.register_provider(:provider_a, provider_a)
        Panda::CMS::Analytics.register_provider(:provider_b, provider_b)
        allow(Panda::CMS.config).to receive(:analytics).and_return({
          provider_a: {enabled: true},
          provider_b: {enabled: true}
        })
        Panda::CMS::Analytics.reset!
      end

      it "renders scripts from all providers" do
        result = helper.panda_analytics
        expect(result).to include("providerA()")
        expect(result).to include("providerB()")
      end
    end

    context "when options are passed through" do
      let(:options_provider) do
        Class.new(Panda::CMS::Analytics::Provider) do
          def configured? = true
          def supports_tracking? = true
          def tracking_configured? = true

          def tracking_script(**options)
            "<script>track(#{options.to_json});</script>".html_safe
          end
        end
      end

      before do
        Panda::CMS::Analytics.register_provider(:options_test, options_provider)
        allow(Panda::CMS.config).to receive(:analytics).and_return({options_test: {enabled: true}})
        Panda::CMS::Analytics.reset!
      end

      it "passes options to the provider" do
        result = helper.panda_analytics(anonymize_ip: true)
        expect(result).to include("anonymize_ip")
      end
    end
  end
end
