module Panda
  module CMS
    class PostsController < ApplicationController
      def show
        @posts_index_page = Panda::CMS::Page.find_by(path: "/#{Panda::CMS.config.posts[:prefix]}")
        @post = Panda::CMS::Post.find_by!(slug: "/#{params[:slug]}")
        @title = @post.title

        render inline: "", status: :ok, layout: "layouts/post"
      end
    end
  end
end
