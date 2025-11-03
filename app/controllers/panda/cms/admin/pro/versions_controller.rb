# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module Pro
        class VersionsController < Panda::CMS::Admin::BaseController
          before_action :set_versionable
          before_action :set_version, only: %i[show diff restore]
          before_action :set_breadcrumbs

          def index
            @versions = @versionable.content_versions.ordered
            @contributors = @versionable.contributors
          end

          def show
            @current_content = @versionable.content
          end

          def diff
            @current_content = @versionable.content
            @version_content = @version.content
            @diff_data = @versionable.diff_with_version(@version.version_number)
          end

          def restore
            if @versionable.restore_version!(@version.version_number, user: current_user)
              redirect_to polymorphic_path([:admin_cms, @versionable, :versions]),
                notice: "Successfully restored to version #{@version.version_number}"
            else
              redirect_to polymorphic_path([:admin_cms, @versionable, :versions]),
                alert: "Failed to restore version"
            end
          end

          private

          def set_versionable
            if params[:post_id]
              @versionable = Panda::CMS::Post.find(params[:post_id])
              @versionable_type = "post"
            elsif params[:page_id]
              @versionable = Panda::CMS::Page.find(params[:page_id])
              @versionable_type = "page"
            else
              raise ActionController::RoutingError, "No versionable resource found"
            end
          end

          def set_version
            @version = @versionable.content_versions.find_by!(version_number: params[:id])
          end

          def set_breadcrumbs
            if @versionable_type == "post"
              add_breadcrumb "Posts", admin_cms_posts_path
              add_breadcrumb @versionable.title, edit_admin_cms_post_path(@versionable.id)
              add_breadcrumb "Version History", admin_cms_post_versions_path(@versionable.id)
            else # page
              add_breadcrumb "Pages", admin_cms_pages_path
              add_breadcrumb @versionable.title, edit_admin_cms_page_path(@versionable.id)
              add_breadcrumb "Version History", admin_cms_page_versions_path(@versionable.id)
            end
          end
        end
      end
    end
  end
end
