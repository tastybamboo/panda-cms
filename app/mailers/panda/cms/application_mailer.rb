module Panda
  module CMS
    class ApplicationMailer < ActionMailer::Base
      default from: "noreply@pandacms.io"
      layout "mailer"
    end
  end
end