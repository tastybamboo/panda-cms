# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Post Categories", type: :request do
  fixtures :panda_cms_post_categories, :panda_cms_posts

  let(:admin_user) { create_admin_user }
  let(:general_category) { panda_cms_post_categories(:general) }
  let(:news_category) { panda_cms_post_categories(:news) }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/cms/post_categories" do
    it "returns a successful response" do
      get "/admin/cms/post_categories"
      expect(response).to have_http_status(:ok)
    end

    it "lists all categories" do
      get "/admin/cms/post_categories"
      expect(response.body).to include("General")
      expect(response.body).to include("News")
    end
  end

  describe "GET /admin/cms/post_categories/new" do
    it "returns a successful response" do
      get "/admin/cms/post_categories/new"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/cms/post_categories" do
    it "creates a new category" do
      expect {
        post "/admin/cms/post_categories", params: {
          post_category: {name: "Tutorials"}
        }
      }.to change(Panda::CMS::PostCategory, :count).by(1)

      category = Panda::CMS::PostCategory.find_by(name: "Tutorials")
      expect(category.slug).to eq("tutorials")
      expect(response).to redirect_to(edit_admin_cms_post_category_path(category))
    end

    it "rejects a category with a blank name" do
      expect {
        post "/admin/cms/post_categories", params: {
          post_category: {name: ""}
        }
      }.not_to change(Panda::CMS::PostCategory, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a duplicate name" do
      expect {
        post "/admin/cms/post_categories", params: {
          post_category: {name: "General"}
        }
      }.not_to change(Panda::CMS::PostCategory, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/cms/post_categories/:id/edit" do
    it "returns a successful response" do
      get "/admin/cms/post_categories/#{news_category.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("News")
    end
  end

  describe "PATCH /admin/cms/post_categories/:id" do
    it "updates a category" do
      patch "/admin/cms/post_categories/#{news_category.id}", params: {
        post_category: {name: "Latest News"}
      }

      expect(response).to redirect_to(edit_admin_cms_post_category_path(news_category))
      expect(news_category.reload.name).to eq("Latest News")
    end

    it "rejects invalid updates" do
      patch "/admin/cms/post_categories/#{news_category.id}", params: {
        post_category: {name: ""}
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(news_category.reload.name).to eq("News")
    end
  end

  describe "DELETE /admin/cms/post_categories/:id" do
    it "prevents deletion of the default General category" do
      expect {
        delete "/admin/cms/post_categories/#{general_category.id}"
      }.not_to change(Panda::CMS::PostCategory, :count)

      expect(response).to redirect_to(admin_cms_post_categories_path)
      follow_redirect!
      expect(response.body).to include("default category cannot be deleted")
    end

    it "prevents deletion of a category with posts" do
      category = Panda::CMS::PostCategory.create!(name: "With Posts")
      Panda::CMS::Post.create!(
        title: "Test Post",
        slug: "/test-delete-category-post",
        user: admin_user,
        author: admin_user,
        post_category: category,
        status: "published"
      )

      expect {
        delete "/admin/cms/post_categories/#{category.id}"
      }.not_to change(Panda::CMS::PostCategory, :count)

      expect(response).to redirect_to(admin_cms_post_categories_path)
      follow_redirect!
      expect(response.body).to include("Cannot delete a category that has posts")
    end

    it "deletes a category with no posts" do
      category = Panda::CMS::PostCategory.create!(name: "Empty Category")

      expect {
        delete "/admin/cms/post_categories/#{category.id}"
      }.to change(Panda::CMS::PostCategory, :count).by(-1)

      expect(response).to redirect_to(admin_cms_post_categories_path)
    end
  end
end
