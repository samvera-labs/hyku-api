# frozen_string_literal: true
module Hyku
  module API
    module V1
      class BaseController < Hyku::API::ApplicationController
        skip_before_action :verify_authenticity_token
        JWT_SECRET = Rails.application.secrets.secret_key_base

        before_action do
          @account = Account.find_by(tenant: params[:tenant_id])
          AccountElevator.switch!(@account.cname) if @account.present?
        end

        before_action do
          if request.headers['Authorization'].present?
            login_from_token(request.authorization.match(/jwt=([\w.]+)\;/).try(:[], 1))
          elsif cookies[:jwt].present?
            login_from_token(cookies[:jwt])
          end
        end

        private

          def login_from_token(token)
            jwt = JWT.decode(token, JWT_SECRET)&.first&.with_indifferent_access
            user = User.find_by(id: jwt['user_id']) if jwt
            sign_in user if user
          rescue JWT::ExpiredSignature, JWT::DecodeError
            render(json: { status: 401, code: 'Invalid credentials', message: "Invalid token" }) && (return)
          end
      end
    end
  end
end
