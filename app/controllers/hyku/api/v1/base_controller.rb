# frozen_string_literal: true
module Hyku
  module API
    module V1
      class BaseController < Hyku::API::ApplicationController
        protect_from_forgery unless: -> { request.format.json? }
        JWT_SECRET = Rails.application.secrets.secret_key_base

        before_action :load_account, :load_token

        private

          def load_token(name = :jwt)
            if request.headers['Authorization'].present?
              login_from_token(request.authorization.split(' ').last)
            elsif cookies[name].present?
              login_from_token(cookies[name])
            end
          end

          def login_from_token(token)
            jwt = JWT.decode(token, JWT_SECRET)&.first&.with_indifferent_access
            user = User.find_by(id: jwt['user_id']) if jwt
            sign_in user if user
          rescue JWT::ExpiredSignature, JWT::DecodeError
            access_denied
          end

          def current_account
            @account ||= Account.find_by(tenant: params[:tenant_id])
          end

          def load_account
            AccountElevator.switch!(current_account.cname) if current_account.present?
          end

          def access_denied(message = "Invalid token")
            render(json: { status: 401, code: 'Invalid credentials', message: message }, status: 401) && false
          end
      end
    end
  end
end
