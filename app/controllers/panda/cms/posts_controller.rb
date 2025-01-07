module Panda
  module CMS
    class PostsController < ApplicationController
      # TODO: Change from layout rendering to standard template rendering
      # inside a /panda/cms/posts/... structure in the application
      def index
        @posts = Panda::CMS::Post.includes(:author).order(published_at: :desc)
        render inline: "", layout: Panda::CMS.config.posts[:layouts][:index]
      end

      def show
        @post = if params[:year] && params[:month]
          # For date-based URLs
          slug = "/#{params[:year]}/#{params[:month]}/#{params[:slug]}"
          Panda::CMS::Post.find_by!(slug: slug)
        else
          # For non-date URLs
          Panda::CMS::Post.find_by!(slug: "/#{params[:slug]}")
        end
        render inline: "", layout: Panda::CMS.config.posts[:layouts][:show]
      end

      def by_month
        @month = Date.new(params[:year].to_i, params[:month].to_i, 1)
        @posts = Panda::CMS::Post
          .where(status: :active)
          .where("DATE_TRUNC('month', published_at) = ?", @month)
          .includes(:author)
          .ordered

        render inline: "", layout: Panda::CMS.config.posts[:layouts][:by_month]
      end
    end
  end
end
