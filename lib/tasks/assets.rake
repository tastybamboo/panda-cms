# frozen_string_literal: true

require "panda/core/testing/assets/runner"

namespace :panda do
  namespace :cms do
    namespace :assets do
      desc "Prepare Panda CMS dummy assets (compile + importmap + copy JS)"
      task prepare_dummy: :environment do
        Panda::Core::Testing::Assets::Runner.prepare(:cms)
      end

      desc "Verify Panda CMS dummy assets (manifest + importmap + HTTP checks)"
      task verify_dummy: :environment do
        Panda::Core::Testing::Assets::Runner.verify(:cms)
      end

      desc "Full CMS dummy asset pipeline (prepare + verify)"
      task dummy: :environment do
        Panda::Core::Testing::Assets::Runner.run(:cms)
      end
    end
  end
end
