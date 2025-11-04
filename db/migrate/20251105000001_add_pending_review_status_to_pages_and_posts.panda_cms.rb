# frozen_string_literal: true

class AddPendingReviewStatusToPagesAndPosts < ActiveRecord::Migration[8.0]
  def up
    # Add pending_review status to pages and posts for content approval workflow
    # This allows content creators to submit drafts for editorial review

    # Note: We're not modifying the enum directly in the database
    # Rails enums are string-based, so we just document the new allowed value
    # The application code will handle the new status value

    # Update any existing pages/posts that might benefit from this status
    # (In a real migration, you'd add logic here if needed)
  end

  def down
    # Convert any pending_review items back to draft
    Panda::CMS::Page.where(status: "pending_review").update_all(status: "draft")
    Panda::CMS::Post.where(status: "pending_review").update_all(status: "draft")
  end
end
