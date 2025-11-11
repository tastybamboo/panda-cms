# frozen_string_literal: true

module Panda
  module CMS
    class PostsController < ApplicationController
      # TODO: Change from layout rendering to standard template rendering
      # inside a /panda/cms/posts/... structure in the application
      def index
        @posts = Panda::CMS::Post.includes(:author).order(published_at: :desc)

        # HTTP caching: Use the most recent post's updated_at for conditional requests
        # Returns 304 Not Modified if no posts have changed since client's last request
        latest_post_timestamp = @posts.maximum(:updated_at) || Time.current
        fresh_when(etag: [@posts.to_a, latest_post_timestamp], last_modified: latest_post_timestamp, public: true)

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

        # HTTP caching: Send ETag and Last-Modified headers for individual posts
        # Returns 304 Not Modified if client's cached version is still valid
        fresh_when(@post, last_modified: @post.updated_at, public: true)

        render inline: "", layout: Panda::CMS.config.posts[:layouts][:show]
      end

      def by_month
        @month = Date.new(params[:year].to_i, params[:month].to_i, 1)
        @posts = Panda::CMS::Post
          .where(status: :active)
          .where("DATE_TRUNC('month', published_at) = ?", @month)
          .includes(:author)
          .ordered

        # HTTP caching: Use the most recent post in this month for conditional requests
        # Returns 304 Not Modified if no posts in this month have changed
        latest_month_timestamp = @posts.maximum(:updated_at) || @month
        fresh_when(etag: [@posts.to_a, @month], last_modified: latest_month_timestamp, public: true)

        render inline: "", layout: Panda::CMS.config.posts[:layouts][:by_month]
      end
    end
  end
end
