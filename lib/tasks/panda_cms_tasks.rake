# frozen_string_literal: true

# Provide consistent namespacing for Panda tasks
# Rails auto-generates panda_cms:* tasks from the module name,
# but we want to use panda:cms:* for consistency across all Panda gems

namespace :panda do
  namespace :cms do
    namespace :install do
      desc "Copy migrations from panda-cms to application"
      task :migrations do
        Rake::Task["panda_cms:install:migrations"].invoke
      end
    end
  end
end
