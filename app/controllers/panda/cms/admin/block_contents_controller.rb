# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class BlockContentsController < ::Panda::Core::AdminController
        before_action :set_page, only: %i[update]
        before_action :set_block_content, only: %i[update]

        # @type PATCH/PUT
        # @return
        def update
          Rails.logger.debug "Content params: #{params.inspect}"
          Rails.logger.debug "Raw content: #{request.raw_post}"

          # Ensure content isn't HTML escaped before saving
          if params[:content].present?
            # Convert ActionController::Parameters to a string if needed
            content_str = params[:content].is_a?(ActionController::Parameters) ? params[:content].to_json : params[:content].to_s
            content = CGI.unescapeHTML(content_str)
          else
            content = nil
          end

          begin
            if content && @block_content.update!(content: content)
              @block_content.page.touch
              render json: @block_content, status: :ok
            else
              render json: @block_content.errors, status: :unprocessable_entity
            end
          rescue => e
            Rails.logger.error "Error updating block content: #{e.message}"
            render json: {error: e.message}, status: :unprocessable_entity
          end
        end

        private

        # @type private
        # @return Panda::CMS::Page
        def set_page
          @page = Panda::CMS::Page.find(params[:page_id])
        end

        # @type private
        # @return Panda::CMS::BlockContent
        def set_block_content
          @block_content = Panda::CMS::BlockContent.find(params[:id])
        end

        # Only allow a list of trusted parameters through.
        # @type private
        # @return ActionController::StrongParameters
        def block_content_params
          params.require(:block_content).permit(:content)
        end
      end
    end
  end
end
