# frozen_string_literal: true

module Panda
  module CMS
    class MinimalTestSeed
      def self.load
        # Create a single admin user if it doesn't exist
        unless Panda::Core::User.exists?(email: "admin@example.com")
          Panda::Core::User.create!(
            firstname: "Admin",
            lastname: "User",
            email: "admin@example.com",
            admin: true,
            image_url: "/panda-cms-assets/panda-nav.png"
          )
        end

        # Create a regular user if it doesn't exist
        unless Panda::Core::User.exists?(email: "regular@example.com")
          Panda::Core::User.create!(
            firstname: "Regular",
            lastname: "User",
            email: "regular@example.com",
            admin: false,
            image_url: "/panda-cms-assets/panda-nav.png"
          )
        end

        # Create a minimal homepage if none exists
        return if Panda::CMS::Page.exists?(path: "/")

        # Create a minimal template first if needed
        template = Panda::CMS::Template.find_or_create_by!(
          name: "Minimal Test Template",
          description: "A minimal template for tests",
          html: "<html><body><header>{{header}}</header><main>{{main}}</main><footer>{{footer}}</footer></body></html>"
        )

        # Create the homepage
        Panda::CMS::Page.create!(
          title: "Home",
          path: "/",
          template: template,
          published: true
        )
      end
    end
  end
end
