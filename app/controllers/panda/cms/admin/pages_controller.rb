# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class PagesController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb, only: %i[index edit new create update]
        # Authentication is automatically enforced by AdminController

        # Lists all pages which can be managed by the administrator
        # @type GET
        # @return ActiveRecord::Collection A list of all pages
        def index
          homepage = Panda::CMS::Page.find_by(path: "/")
          archived_count = Panda::CMS::Page.archived.count
          show_archived = params[:show_archived] == "true"
          render :index, locals: {root_page: homepage, archived_count: archived_count, show_archived: show_archived}
        end

        # Loads the add page form
        # @type GET
        def new
          locals = setup_new_page_form(page: page)
          render :new, locals: locals
        end

        # Loads the page editor
        # @type GET
        def edit
          # Add all ancestor pages to breadcrumbs (excluding homepage at depth 0)
          page.ancestors.select { |anc| anc.depth > 0 }.each do |ancestor|
            add_breadcrumb ancestor.title, edit_admin_cms_page_path(ancestor)
          end

          add_breadcrumb page.title, edit_admin_cms_page_path(page)

          # Set session variables for secure iframe editing
          # This replaces the less secure ?embed_id= URL parameter approach
          session[:panda_cms_editing_page_id] = page.id.to_s
          session[:panda_cms_editing_expires_at] = 30.minutes.from_now.iso8601

          render :edit, locals: {page: page, template: page.template}
        end

        # POST /admin/pages
        def create
          page = Panda::CMS::Page.new(page_params)

          # Normalize empty path to nil so presence validation triggers
          page.path = nil if page.path.blank?

          # Set the full path before validation if we have a parent
          if page.parent && page.parent.path != "/" && page.path.present? && !page.path.start_with?(page.parent.path)
            # Only prepend parent path if it's not already included
            page.path = page.parent.path + page.path
          end

          if page.save
            redirect_to edit_admin_cms_page_path(page), notice: "The page was successfully created."
          else
            flash.now[:error] = page.errors.full_messages.to_sentence
            locals = setup_new_page_form(page: page)
            render :new, locals: locals, status: :unprocessable_entity
          end
        end

        # Reorder a page relative to a sibling
        # @type POST
        def reorder
          target = Panda::CMS::Page.find(params[:target_id])

          if page.archived? || target.archived?
            return render json: {error: "Cannot reorder archived pages"}, status: :unprocessable_entity
          end

          if page.depth == 0 || target.depth == 0
            return render json: {error: "Cannot reorder root page"}, status: :unprocessable_entity
          end

          unless page.parent_id == target.parent_id
            return render json: {error: "Can only reorder siblings"}, status: :unprocessable_entity
          end

          case params[:position]
          when "before"
            page.move_to_left_of(target)
          when "after"
            page.move_to_right_of(target)
          else
            return render json: {error: "Invalid position"}, status: :unprocessable_entity
          end

          # Regenerate auto menus that include these pages
          ancestor_ids = page.self_and_ancestors.pluck(:id)
          Panda::CMS::Menu.where(kind: "auto", start_page_id: ancestor_ids).find_each(&:generate_auto_menu_items)

          render json: {success: true}
        end

        # @type PATCH/PUT
        # @return
        def update
          if page.update(page_params)
            redirect_to edit_admin_cms_page_path(page),
              status: :see_other,
              flash: {success: "This page was successfully updated!"}
          else
            flash[:error] = "There was an error updating the page."
            render :edit, locals: {page: page, template: page.template}, status: :unprocessable_entity
          end
        end

        private

        # Get the page from the ID
        # @type private
        # @return Panda::CMS::Page
        def page
          @page ||= if params[:id]
            Panda::CMS::Page.find(params[:id])
          else
            Panda::CMS::Page.new(template: Panda::CMS::Template.default)
          end
        end

        def set_initial_breadcrumb
          add_breadcrumb "Pages", admin_cms_pages_path
        end

        def setup_new_page_form(page:)
          add_breadcrumb "Add Page", new_admin_cms_page_path
          {
            page: page,
            available_templates: Panda::CMS::Template.available
          }
        end

        # Only allow a list of trusted parameters through.
        # @type private
        # @return ActionController::StrongParameters
        def page_params
          params.require(:page).permit(
            :title, :path, :panda_cms_template_id, :parent_id, :status, :page_type,
            :seo_title, :seo_description, :seo_keywords, :seo_index_mode, :canonical_url,
            :og_title, :og_description, :og_type, :og_image, :inherit_seo
          )
        end
      end
    end
  end
end
