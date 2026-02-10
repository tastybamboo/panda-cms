# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Block Contents", type: :request do
  fixtures :panda_cms_templates, :panda_cms_pages, :panda_cms_blocks, :panda_cms_block_contents

  let(:admin_user) { create_admin_user }
  let(:page) { panda_cms_pages(:about_page) }
  let(:code_block_content) { panda_cms_block_contents(:about_page_html_code) }
  let(:text_block_content) { panda_cms_block_contents(:about_page_plain_text) }

  describe "PATCH /admin/cms/pages/:page_id/block_contents/:id" do
    context "when user is an admin" do
      before do
        post "/admin/test_sessions", params: {user_id: admin_user.id}
      end

      it "allows updating code blocks" do
        patch "/admin/cms/pages/#{page.id}/block_contents/#{code_block_content.id}",
          params: {content: "<p>Updated code</p>"},
          as: :json

        expect(response).to have_http_status(:ok)
        expect(code_block_content.reload.content).to eq("<p>Updated code</p>")
      end

      it "allows updating non-code blocks" do
        patch "/admin/cms/pages/#{page.id}/block_contents/#{text_block_content.id}",
          params: {content: "Updated text"},
          as: :json

        expect(response).to have_http_status(:ok)
        expect(text_block_content.reload.content).to eq("Updated text")
      end

      it "rejects block content that belongs to a different page" do
        other_page_content = panda_cms_block_contents(:services_page_html_code)

        patch "/admin/cms/pages/#{page.id}/block_contents/#{other_page_content.id}",
          params: {content: "Cross-page attack"},
          as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Authorization behavior (authorize_code_block_edit) is tested at the
  # controller concern level, following the same pattern as panda-core's
  # authorizable_spec.rb. The TestSessionsController only authenticates
  # admin users, and admin users bypass all authorization checks, so
  # non-admin authorization cannot be tested via full request specs.
  describe "authorize_code_block_edit" do
    let(:controller_class) do
      Class.new(Panda::CMS::Admin::BlockContentsController) do
        attr_accessor :_current_user, :_block_content

        def current_user
          _current_user
        end

        # Expose private method for testing
        public :authorize_code_block_edit
      end
    end

    let(:controller) { controller_class.new }
    let(:regular_user) { create_regular_user }
    let(:code_block) { panda_cms_blocks(:html_code_block) }
    let(:text_block) { panda_cms_blocks(:plain_text_block) }

    before do
      @original_authorization_policy = Panda::Core.config.authorization_policy
      Panda::Core.config.authorization_policy = ->(_user, action, _resource) {
        action == :access_admin
      }
    end

    after do
      Panda::Core.config.authorization_policy = @original_authorization_policy
    end

    it "checks permission for code blocks" do
      controller._current_user = regular_user
      controller.instance_variable_set(:@block_content, code_block_content)

      # authorized_for? returns false for :edit_code_blocks with this policy
      expect(controller.authorized_for?(:edit_code_blocks)).to be false
    end

    it "skips permission check for non-code blocks" do
      controller._current_user = regular_user
      controller.instance_variable_set(:@block_content, text_block_content)

      # authorize_code_block_edit returns early for non-code blocks
      expect(controller.authorize_code_block_edit).to be_nil
    end

    it "allows code blocks when permission is granted" do
      Panda::Core.config.authorization_policy = ->(_user, action, _resource) {
        %i[access_admin edit_code_blocks].include?(action)
      }
      controller._current_user = regular_user

      expect(controller.authorized_for?(:edit_code_blocks)).to be true
    end

    it "always allows admin users" do
      controller._current_user = admin_user

      expect(controller.authorized_for?(:edit_code_blocks)).to be true
    end
  end
end
