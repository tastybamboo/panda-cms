# frozen_string_literal: true

require "pathname"
require "panda/assets/runner"

namespace :panda do
  namespace :cms do
    namespace :assets do
      def dummy_root
        root = Rails.root
        return root if root.basename.to_s == "dummy"

        candidate = root.join("spec/dummy")
        return candidate if candidate.exist?

        raise "❌ Cannot find dummy root – expected #{candidate}"
      end

      def engine_root
        Panda::CMS::Engine.root
      end

      def engine_js_roots
        roots = []
        app_js = engine_root.join("app/javascript/panda/cms")
        vendor_js = engine_root.join("vendor/javascript/panda/cms")

        roots << app_js if app_js.directory?
        roots << vendor_js if vendor_js.directory?

        roots
      end

      desc "Prepare Panda CMS dummy assets (compile + importmap + copy JS)"
      task prepare_dummy: :environment do
        config = {
          dummy_root: dummy_root,
          engine_js_roots: engine_js_roots,
          engine_js_prefix: "panda/cms"
        }

        result = Panda::Assets::Runner.prepare(:cms, config)
        abort("❌ Panda CMS dummy prepare failed") unless result.ok
      end

      desc "Verify Panda CMS dummy assets (manifest + importmap + HTTP checks)"
      task verify_dummy: :environment do
        config = {
          dummy_root: dummy_root,
          engine_js_roots: engine_js_roots,
          engine_js_prefix: "panda/cms"
        }

        result = Panda::Assets::Runner.verify(:cms, config)
        abort("❌ Panda CMS dummy verify failed") unless result.ok
      end

      desc "Full Panda CMS dummy asset pipeline (prepare + verify)"
      task dummy: :environment do
        config = {
          dummy_root: dummy_root,
          engine_js_roots: engine_js_roots,
          engine_js_prefix: "panda/cms"
        }

        result = Panda::Assets::Runner.run(:cms, config)
        abort("❌ Panda CMS dummy pipeline failed") unless result.ok
      end

      # Meta-task to drive both core + cms pipelines from panda-cms CI
      desc "Prepare + verify Panda Core and CMS dummy assets"
      task prepare_and_verify_all: :environment do
        Rake::Task["panda:core:assets:dummy"].invoke
        Rake::Task["panda:cms:assets:dummy"].invoke
      end
    end
  end
end
