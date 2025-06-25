# frozen_string_literal: true

module Panda
  module CMS
    class FormMailer < Panda::CMS::ApplicationMailer
      def notification_email(form:, form_submission:)
        # TODO: Handle fields named just "name", and "email" better
        @submission_data = form_submission.data
        @sender_name = "#{@submission_data["first_name"]} #{@submission_data["last_name"]}"
        @sender_email = @submission_data["email"].to_s

        mail(
          subject: "#{form.name}: #{form_submission.created_at.strftime("%d %b %Y %H:%M")}",
          to: email_address_with_name("james@otaina.co.uk", "James Inman"),
          from: email_address_with_name("noreply@pandacms.io", "Panda CMS"),
          reply_to: email_address_with_name(@sender_email, @sender_name),
          track_opens: "true",
          message_stream: "outbound"
        )
      end
    end
  end
end
