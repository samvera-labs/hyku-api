# frozen_string_literal: true
module Hyku
  module API
    module V1
      class ContactFormController < Hyku::API::ApplicationController
        def create
          @contact_form = Hyrax::ContactForm.new(contact_form_params)

          if @contact_form.spam?
            render json: { code: 422, status: :spam_not_sent }
          elsif @contact_form.valid?
            mailer = Hyrax::ContactMailer.contact(@contact_form)
            mailer.to = Hyrax.config.contact_email
            mailer.deliver_now
            render json: { code: 201,  status: :created }
          else
            render json: "Your contact form is missing one of the following compulsory fields :name, :category, :email, :subject, :message"
          end
        end

        private

          def build_contact_form
            @contact_form = Hyrax::ContactForm.new(contact_form_params)
          end

          def contact_form_params
            params.permit(:contact_method, :category, :name, :email, :subject, :message)
          end
      end
    end
  end
end
