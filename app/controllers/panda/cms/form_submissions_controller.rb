module Panda
  module CMS
    class FormSubmissionsController < ApplicationController
      invisible_captcha only: [:create]

      def create
        vars = params.except(:authenticity_token, :controller, :action, :id)

        form = Panda::CMS::Form.find(params[:id])
        form_submission = Panda::CMS::FormSubmission.create(form_id: params[:id], data: vars.to_unsafe_h)
        form.update(submission_count: form.submission_count + 1)

        Panda::CMS::FormMailer.notification_email(form: form, form_submission: form_submission).deliver_now

        if (completion_path = form&.completion_path)
          redirect_to completion_path
        else
          # TODO: This isn't a great fallback, we should do something nice here...
          # Perhaps a simple JS alert when sent?
          redirect_to "/"
        end
      end
    end
  end
end
