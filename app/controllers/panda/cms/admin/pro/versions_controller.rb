# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module Pro
        class VersionsController < Panda::CMS::Admin::BaseController
          before_action :set_post
          before_action :set_version, only: %i[show diff restore]

          def index
            @versions = @post.content_versions.ordered.page(params[:page]).per(20)
            @contributors = @post.contributors
          end

          def show
            @current_content = @post.versionable_content
          end

          def diff
            @current_content = @post.versionable_content
            @version_content = @version.content
            @diff_data = @post.diff_with_version(@version.version_number)
          end

          def restore
            if @post.restore_version!(@version.version_number, user: current_user)
              redirect_to admin_cms_post_versions_path(@post),
                notice: "Successfully restored to version #{@version.version_number}"
            else
              redirect_to admin_cms_post_versions_path(@post),
                alert: "Failed to restore version"
            end
          end

          private

          def set_post
            @post = Panda::CMS::Post.find(params[:post_id])
          end

          def set_version
            @version = @post.content_versions.find_by!(version_number: params[:id])
          end
        end
      end
    end
  end
end
