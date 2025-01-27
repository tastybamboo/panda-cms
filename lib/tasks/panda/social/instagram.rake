namespace :panda do
  namespace :social do
    namespace :instagram do
      desc "Sync recent Instagram posts"
      task sync: :environment do
        if Panda::CMS.config.instagram[:access_token].present?
          puts "Starting Instagram sync..."
          Panda::Social::InstagramFeedService.new(
            Panda::CMS.config.instagram[:access_token]
          ).sync_recent_posts
          puts "Instagram sync (@#{Panda::CMS.config.instagram[:username]}) completed"
        else
          puts "Instagram access token not configured"
        end
      end
    end
  end
end
