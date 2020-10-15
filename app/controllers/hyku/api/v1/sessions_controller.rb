# frozen_string_literal: true
require 'jwt'

module Hyku
  module API
    module V1
      class SessionsController < Hyku::API::ApplicationController
        def create
          user = User.find_for_database_authentication(email: params[:email])
          raise RuntimeError unless user&.valid_password?(params[:password])

          response.set_cookie(
            :jwt,
            value: generate_token(user), expires: 1.hour.from_now, path: '/', same_site: :none,
            domain: ('.' + request.host), secure: true, httponly: true
          )

          # participants = adminset_permissions(user)
          participants = []
          # user_type = user_roles(user)
          user_type = []
          render json: user.slice(:email).merge(participants: participants, type: user_type)
        rescue RuntimeError
          render json: { status: 401, code: 'Invalid credentials', message: "Invalid email or password." }
        end

        def destroy; end

        def refresh; end

        private

          def generate_token(user)
            JWT.encode({ user_id: user.id, exp: (Time.now.utc + 1.hour).to_i }, JWT_SECRET)
          end
      end
    end
  end
end
