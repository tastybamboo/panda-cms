namespace :panda do
  namespace :cms do
    desc "Copy any missing migrations from panda-cms to the host application"
    task :install do
      # Copy migrations
      Rake::Task["railties:install:migrations"].invoke
    end

    namespace :test do
      desc "Prepare test database by copying migrations and running them"
      task :prepare do
        # Remove all existing migrations from dummy app
        FileUtils.rm_rf(Dir.glob("spec/dummy/db/migrate/*"))

        # Copy all migrations from main app to dummy app
        FileUtils.cp_r(Dir.glob("db/migrate/*"), "spec/dummy/db/migrate/")

        # Drop and recreate test database
        system("cd spec/dummy && RAILS_ENV=test rails db:drop db:create db:migrate")
      end
    end
  end
end
