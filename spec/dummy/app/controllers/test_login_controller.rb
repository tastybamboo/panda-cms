# frozen_string_literal: true

class TestLoginController < ApplicationController
  # Development-only controller for bypassing authentication
  before_action :ensure_development_mode

  def show
    user_id = params[:id]

    # Store user_id in session (matches OmniAuth callback behavior)
    session[:user_id] = user_id

    redirect_to "/admin", notice: "Logged in as test user"
  rescue => e
    redirect_to "/", alert: "Login failed: #{e.message}"
  end

  private

  def ensure_development_mode
    unless Rails.env.development?
      raise ActionController::RoutingError, "Test login only available in development mode"
    end
  end
end
