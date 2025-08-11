# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module Settings
        class BulkEditorController < ::Panda::CMS::Admin::BaseController
          before_action :set_initial_breadcrumb, only: %i[new]

          def new
            @json_data = BulkEditor.export
          end

          def create
            begin
              debug_output = BulkEditor.import(params[:site_content])
            rescue JSON::ParserError
              redirect_to admin_settings_bulk_editor_path,
                flash: {error: "Error parsing content; are you sure this update is valid? Reverting..."}
              return
            end

            # Grab the latest content back so it's all formatted properly
            @json_data = BulkEditor.export

            if debug_output[:error].empty? && debug_output[:warning].empty? && debug_output[:success].empty?
              redirect_to admin_settings_bulk_editor_path, flash: {success: "No changes were found!"}
            else
              @debug = debug_output
              render :new, flash: {warning: "Please review the output below for more information."}
            end
          end

          private

          def set_initial_breadcrumb
            add_breadcrumb "Settings", admin_settings_path
            add_breadcrumb "Bulk Editor", "#"
          end
        end
      end
    end
  end
end
