# frozen_string_literal: true

require "json"

module Panda
  module CMS
    module Admin
      class PostsController < ApplicationController
        before_action :set_initial_breadcrumb, only: %i[index new edit create update]
        before_action :authenticate_admin_user!

        # Get all posts
        # @type GET
        # @return ActiveRecord::Collection A list of all posts
        def index
          posts = Panda::CMS::Post.with_author.ordered
          render :index, locals: {posts: posts}
        end

        # Loads the add post form
        # @type GET
        def new
          locals = setup_new_post_form
          render :new, locals: locals
        end

        # Loads the post editor
        # @type GET
        def edit
          add_breadcrumb post.title, edit_admin_post_path(post.admin_param)
          render :edit, locals: {post: post}
        end

        # POST /admin/posts
        def create
          @post = Panda::CMS::Post.new(post_params)
          @post.user_id = current_user.id
          @post.content = parse_content(post_params[:content]) # Parse the content before saving

          if @post.save
            Rails.logger.debug "Post saved successfully"
            flash[:success] = "The post was successfully created!"
            redirect_to edit_admin_post_path(@post.admin_param), status: :see_other
          else
            Rails.logger.debug "Post save failed: #{@post.errors.full_messages.inspect}"
            flash.now[:error] = @post.errors.full_messages.join(", ")
            locals = setup_new_post_form(post: @post, preserved_content: post_params[:content])
            render :new, locals: locals, status: :unprocessable_entity
          end
        end

        # @type PATCH/PUT
        # @return
        def update
          Rails.logger.debug "Current content: #{post.content.inspect}"
          Rails.logger.debug "New content from params: #{post_params[:content].inspect}"

          # Parse the content before updating
          update_params = post_params
          update_params[:content] = parse_content(post_params[:content])
          update_params[:user_id] = current_user.id
          if post.update(update_params)
            Rails.logger.debug "Post updated successfully"
            add_breadcrumb post.title, edit_admin_post_path(post.admin_param)
            flash[:success] = "The post was successfully updated!"
            redirect_to edit_admin_post_path(post.admin_param), status: :see_other
          else
            Rails.logger.debug "Post update failed: #{post.errors.full_messages.inspect}"
            Rails.logger.debug "Preserving content: #{post_params[:content].inspect}"
            add_breadcrumb post.title.presence || "Edit Post", edit_admin_post_path(post.admin_param)
            flash.now[:error] = post.errors.full_messages.join(", ")
            render :edit, locals: {
              post: post,
              preserved_content: post_params[:content]
            }, status: :unprocessable_entity
          end
        end

        private

        # Get the post from the ID
        # @type private
        # @return Panda::CMS::Post
        def post
          @post ||= if params[:id]
            Panda::CMS::Post.find(params[:id])
          else
            Panda::CMS::Post.new(
              status: "active",
              published_at: Time.zone.now
            )
          end
        end

        def set_initial_breadcrumb
          add_breadcrumb "Posts", admin_posts_path
        end

        def setup_new_post_form(post: nil, preserved_content: nil)
          add_breadcrumb "Add Post", new_admin_post_path

          post ||= Panda::CMS::Post.new(
            status: "active",
            published_at: Time.zone.now
          )

          {
            post: post,
            url: admin_posts_path,
            preserved_content: preserved_content
          }
        end

        # Only allow a list of trusted parameters through.
        # @type private
        # @return ActionController::StrongParameters
        def post_params
          params.require(:post).permit(
            :title,
            :slug,
            :status,
            :published_at,
            :author_id,
            :content
          )
        end

        def parse_content(content)
          return {} if content.blank?

          begin
            # If content is already a hash, return it
            return content if content.is_a?(Hash)

            # If it's a string, try to parse it as JSON
            parsed = JSON.parse(content)

            # Ensure we have a hash with expected structure
            if parsed.is_a?(Hash) && parsed["blocks"].is_a?(Array)
              parsed
            else
              # If structure is invalid, return empty blocks structure
              {"blocks" => []}
            end
          rescue JSON::ParserError => e
            Rails.logger.error "Failed to parse post content: #{e.message}"
            {"blocks" => []}
          end
        end
      end
    end
  end
end
