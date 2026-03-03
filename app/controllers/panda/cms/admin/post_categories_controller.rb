# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class PostCategoriesController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb
        before_action :set_post_category, only: %i[edit update destroy]

        def index
          post_categories = Panda::CMS::PostCategory
            .left_joins(:posts)
            .select("panda_cms_post_categories.*, COUNT(panda_cms_posts.id) AS posts_count")
            .group("panda_cms_post_categories.id")
            .ordered
          render :index, locals: {post_categories: post_categories}
        end

        def new
          post_category = Panda::CMS::PostCategory.new
          add_breadcrumb "New Category", new_admin_cms_post_category_path
          render :new, locals: {post_category: post_category}
        end

        def create
          post_category = Panda::CMS::PostCategory.new(post_category_params)

          if post_category.save
            redirect_to edit_admin_cms_post_category_path(post_category), notice: "Category was successfully created."
          else
            add_breadcrumb "New Category", new_admin_cms_post_category_path
            render :new, locals: {post_category: post_category}, status: :unprocessable_entity
          end
        end

        def edit
          add_breadcrumb @post_category.name, edit_admin_cms_post_category_path(@post_category)
          render :edit, locals: {post_category: @post_category}
        end

        def update
          if @post_category.update(post_category_params)
            redirect_to edit_admin_cms_post_category_path(@post_category), notice: "Category was successfully updated.", status: :see_other
          else
            add_breadcrumb @post_category.name, edit_admin_cms_post_category_path(@post_category)
            render :edit, locals: {post_category: @post_category}, status: :unprocessable_entity
          end
        end

        def destroy
          if !@post_category.deletable?
            redirect_to admin_cms_post_categories_path, alert: "The default category cannot be deleted.", status: :see_other
          elsif @post_category.posts.any?
            redirect_to admin_cms_post_categories_path, alert: "Cannot delete a category that has posts. Reassign them first.", status: :see_other
          else
            @post_category.destroy
            redirect_to admin_cms_post_categories_path, notice: "Category was successfully deleted.", status: :see_other
          end
        end

        private

        def set_post_category
          @post_category = Panda::CMS::PostCategory.find(params[:id])
        end

        def set_initial_breadcrumb
          add_breadcrumb "Post Categories", admin_cms_post_categories_path
        end

        def post_category_params
          params.require(:post_category).permit(:name, :slug, :description)
        end
      end
    end
  end
end
