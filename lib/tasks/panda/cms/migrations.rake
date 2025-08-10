# frozen_string_literal: true

namespace :panda do
  namespace :cms do
    namespace :install do
      desc "Copy migrations from panda_cms to application"
      task :migrations do
        # Delegate to the auto-generated task
        Rake::Task["panda_cms:install:migrations"].invoke
      end
    end
  end
end