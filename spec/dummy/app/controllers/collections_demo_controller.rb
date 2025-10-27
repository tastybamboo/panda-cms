# frozen_string_literal: true

class CollectionsDemoController < ApplicationController
  helper Panda::CMS::ApplicationHelper

  def index
    @title = "Collections Demo"
  end
end
