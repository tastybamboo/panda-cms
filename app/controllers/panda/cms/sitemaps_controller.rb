# frozen_string_literal: true

module Panda
  module CMS
    class SitemapsController < ApplicationController
      def index
        @pages = Panda::CMS::Page
          .where(status: :active)
          .where.not(page_type: [:hidden_type, :system])
          .where(seo_index_mode: :visible)
          .order(:lft)

        @posts = if Panda::CMS.config.posts[:enabled]
          Panda::CMS::Post
            .where(status: :active)
            .where(seo_index_mode: :visible)
            .order(published_at: :desc)
        else
          Panda::CMS::Post.none
        end

        latest = [@pages.maximum(:updated_at), @posts.maximum(:updated_at)].compact.max
        if latest && stale?(last_modified: latest, public: true)
          respond_to do |format|
            format.xml
          end
        end
      end
    end
  end
end
