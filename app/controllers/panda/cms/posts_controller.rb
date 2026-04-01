# frozen_string_literal: true

module Panda
  module CMS
    class PostsController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      before_action :set_default_ivars

      # TODO: Change from layout rendering to standard template rendering
      # inside a /panda/cms/posts/... structure in the application
      def index
        @posts = Panda::CMS::Post.where(status: :published).includes(:author, :post_category).order(published_at: :desc)
        @post_categories = Panda::CMS::PostCategory.ordered

        # HTTP caching: Use the most recent post's updated_at for conditional requests
        # Returns 304 Not Modified if no posts have changed since client's last request
        latest_post_timestamp = @posts.maximum(:updated_at) || Time.current
        return unless stale?(etag: [@posts.count, latest_post_timestamp], last_modified: latest_post_timestamp, public: true)

        respond_to do |format|
          format.html { render inline: "", layout: Panda::CMS.config.posts[:layouts][:index] }
          format.atom { @posts = @posts.limit(20) }
        end
      end

      def show
        @post = if params[:year] && params[:month]
          # For date-based URLs
          slug = "/#{params[:year]}/#{params[:month]}/#{params[:slug]}"
          Panda::CMS::Post.servable.find_by!(slug: slug)
        else
          # For non-date URLs
          Panda::CMS::Post.servable.find_by!(slug: "/#{params[:slug]}")
        end

        # HTTP caching: Send ETag and Last-Modified headers for individual posts
        # Returns 304 Not Modified if client's cached version is still valid
        return unless stale?(@post, last_modified: @post.updated_at, public: true)

        render inline: "", layout: Panda::CMS.config.posts[:layouts][:show]
      end

      def by_category
        @post_category = Panda::CMS::PostCategory.find_by!(slug: params[:category_slug])
        @posts = Panda::CMS::Post
          .where(status: :published)
          .where(post_category: @post_category)
          .includes(:author, :post_category)
          .ordered

        latest_timestamp = @posts.maximum(:updated_at) || @post_category.updated_at
        return unless stale?(etag: [@post_category.cache_key_with_version, @posts.count, latest_timestamp], last_modified: latest_timestamp, public: true)

        render inline: "", layout: Panda::CMS.config.posts[:layouts][:index]
      end

      def by_month
        @month = Date.new(params[:year].to_i, params[:month].to_i, 1)
        @posts = Panda::CMS::Post
          .where(status: :published)
          .where("DATE_TRUNC('month', published_at) = ?", @month)
          .includes(:author)
          .ordered

        # HTTP caching: Use the most recent post in this month for conditional requests
        # Returns 304 Not Modified if no posts in this month have changed
        latest_month_timestamp = @posts.maximum(:updated_at) || @month
        return unless stale?(etag: [@month, @posts.count, latest_month_timestamp], last_modified: latest_month_timestamp, public: true)

        render inline: "", layout: Panda::CMS.config.posts[:layouts][:by_month]
      end

      private

      # Host app layouts may reference @page and @overrides (e.g. shared header
      # partials). StrictIvars requires them to be set before first access.
      def set_default_ivars
        @page = nil
        @overrides = {}
      end

      def render_not_found
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
      end
    end
  end
end
