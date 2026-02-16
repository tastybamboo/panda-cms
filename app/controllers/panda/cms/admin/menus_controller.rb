# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class MenusController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb, only: %i[index new edit]
        before_action :set_menu, only: %i[edit update destroy toggle_pin]

        # Lists all menus which can be managed by the administrator
        # @type GET
        # @return ActiveRecord::Collection An array of all menus
        def index
          menus = Panda::CMS::Menu.order(:name)
          render :index, locals: {menus: menus}
        end

        # @type GET
        def new
          menu = Panda::CMS::Menu.new
          add_breadcrumb "New Menu", new_admin_cms_menu_path
          render :new, locals: {menu: menu}
        end

        # @type POST
        def create
          menu = Panda::CMS::Menu.new(menu_params_with_defaults)

          if menu.save
            reorder_menu_items(menu)
            redirect_to admin_cms_menus_path, notice: "Menu was successfully created.", status: :see_other
          else
            render :new, locals: {menu: menu}, status: :unprocessable_entity
          end
        end

        # @type GET
        def edit
          add_breadcrumb @menu.name, edit_admin_cms_menu_path(@menu)
          render :edit
        end

        # @type PATCH/PUT
        def update
          if @menu.update(menu_params_with_defaults)
            reorder_menu_items(@menu)
            redirect_to admin_cms_menus_path, notice: "Menu was successfully updated.", status: :see_other
          else
            render :edit, status: :unprocessable_entity
          end
        end

        # @type DELETE
        def destroy
          @menu.destroy
          redirect_to admin_cms_menus_path, notice: "Menu was successfully deleted.", status: :see_other
        end

        # @type POST
        def toggle_pin
          page_id = params[:page_id].to_s
          if @menu.page_pinned?(page_id)
            @menu.unpin_page(page_id)
          else
            @menu.pin_page(page_id)
          end
          @menu.save!
          redirect_to edit_admin_cms_menu_path(@menu), notice: "Pin state updated.", status: :see_other
        end

        private

        def set_menu
          @menu = Panda::CMS::Menu.find(params[:id])
        end

        def menu_params
          params.require(:menu).permit(:name, :kind, :start_page_id, :promote_active_item, menu_items_attributes: [:id, :text, :external_url, :panda_cms_page_id, :position, :_destroy])
        end

        def menu_params_with_defaults
          permitted = menu_params
          return permitted unless permitted[:kind] == "auto"

          permitted[:start_page_id] = permitted[:start_page_id].presence || Panda::CMS::Page.find_by(path: "/")&.id
          permitted
        end

        def reorder_menu_items(menu)
          attrs = params.dig(:menu, :menu_items_attributes)
          return unless attrs.present?

          items_with_positions = attrs.values
            .reject { |a| a[:_destroy] == "1" }
            .select { |a| a[:position].present? }
            .sort_by { |a| a[:position].to_i }

          return if items_with_positions.size < 2

          menu.menu_items.reload

          ordered_items = items_with_positions.filter_map do |a|
            if a[:id].present?
              menu.menu_items.find { |item| item.id == a[:id] }
            else
              menu.menu_items.find { |item| item.text == a[:text] }
            end
          end

          return if ordered_items.size < 2

          # Skip if already in correct order
          current_ids = menu.menu_items.order(:lft).map(&:id)
          desired_ids = ordered_items.map(&:id)
          return if current_ids == desired_ids

          ordered_items.each_cons(2) do |left_item, right_item|
            right_item.reload.move_to_right_of(left_item.reload)
          end
        end

        def set_initial_breadcrumb
          add_breadcrumb "Menus", admin_cms_menus_path
        end
      end
    end
  end
end
