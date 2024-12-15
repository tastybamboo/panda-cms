# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class PostsController < ApplicationController
        before_action :set_initial_breadcrumb, only: %i[index new edit create update]
        before_action :set_paper_trail_whodunnit, only: %i[create update]
        before_action :authenticate_admin_user!

        # Get all posts
        # @type GET
        # @return ActiveRecord::Collection A list of all posts
        def index
          posts = Panda::CMS::Post.with_user.ordered
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

          # Get the latest version's content or fall back to post's content
          preserved_content = if post.versions.exists?
            reified_post = post.versions.last.reify
            reified_post&.content || post.content
          else
            post.content
          end

          render :edit, locals: {
            post: post,
            url: admin_post_path(post.admin_param),
            preserved_content: preserved_content
          }
        end

        # POST /admin/posts
        def create
          @post = Panda::CMS::Post.new(post_params)
          Rails.logger.debug "Creating post with params: #{post_params.inspect}"
          Rails.logger.debug "Post content: #{@post.content.inspect}"

          if @post.save
            Rails.logger.debug "Post saved successfully"
            redirect_to edit_admin_post_path(@post.admin_param), notice: "Post was successfully created."
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
          Rails.logger.debug "Updating post with params: #{post_params.inspect}"
          Rails.logger.debug "Current content: #{post.content.inspect}"
          Rails.logger.debug "New content from params: #{post_params[:content].inspect}"

          if post.update(post_params)
            Rails.logger.debug "Post updated successfully"
            add_breadcrumb post.title, edit_admin_post_path(post.admin_param)
            redirect_to edit_admin_post_path(post.admin_param),
              status: :see_other,
              flash: {success: "The post was successfully updated!"}
          else
            Rails.logger.debug "Post update failed: #{post.errors.full_messages.inspect}"
            Rails.logger.debug "Preserving content: #{post_params[:content].inspect}"
            flash[:error] = post.errors.full_messages.join(", ")
            add_breadcrumb post.title.presence || "Edit Post", edit_admin_post_path(post.admin_param)
            render :edit, locals: {
              post: post,
              url: admin_post_path(post.admin_param),
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
            :user_id,
            content: {}
          ).tap do |permitted_params|
            if permitted_params[:content].present?
              permitted_params[:content] = if permitted_params[:content].is_a?(String)
                Rails.logger.debug "Parsing content from string: #{permitted_params[:content]}"
                JSON.parse(permitted_params[:content])
              elsif permitted_params[:content].is_a?(ActionController::Parameters)
                Rails.logger.debug "Converting content from parameters: #{permitted_params[:content].inspect}"
                permitted_params[:content].to_unsafe_h
              else
                Rails.logger.debug "Using content as is: #{permitted_params[:content].inspect}"
                permitted_params[:content]
              end
            end
          end
        end
      end
    end
  end
end
