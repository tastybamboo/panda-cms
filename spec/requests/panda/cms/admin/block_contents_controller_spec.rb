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

        expect {
          patch "/admin/cms/pages/#{page.id}/block_contents/#{other_page_content.id}",
            params: {content: "Cross-page attack"},
            as: :json
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user lacks edit_code_blocks permission" do
      let(:editor_user) { create_regular_user }

      before do
        # Grant admin access but deny code block editing
        Panda::Core.config.authorization_policy = ->(_user, action, _resource) {
          action == :access_admin
        }
        post "/admin/test_sessions", params: {user_id: editor_user.id}
      end

      after do
        Panda::Core.reset_config!
      end

      it "rejects code block updates with 403" do
        patch "/admin/cms/pages/#{page.id}/block_contents/#{code_block_content.id}",
          params: {content: "<script>alert('xss')</script>"},
          as: :json

        expect(response).to have_http_status(:forbidden)
        expect(code_block_content.reload.content).not_to include("alert")
      end

      it "allows updating non-code blocks" do
        patch "/admin/cms/pages/#{page.id}/block_contents/#{text_block_content.id}",
          params: {content: "Updated by editor"},
          as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user has edit_code_blocks permission" do
      let(:editor_user) { create_regular_user }

      before do
        Panda::Core.config.authorization_policy = ->(_user, action, _resource) {
          %i[access_admin edit_code_blocks].include?(action)
        }
        post "/admin/test_sessions", params: {user_id: editor_user.id}
      end

      after do
        Panda::Core.reset_config!
      end

      it "allows code block updates" do
        patch "/admin/cms/pages/#{page.id}/block_contents/#{code_block_content.id}",
          params: {content: "<div>Trusted content</div>"},
          as: :json

        expect(response).to have_http_status(:ok)
        expect(code_block_content.reload.content).to eq("<div>Trusted content</div>")
      end
    end
  end
end
