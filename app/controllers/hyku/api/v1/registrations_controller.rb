# frozen_string_literal: true
require 'jwt'

module Hyku
  module API
    module V1
      class RegistrationsController < BaseController
        def create
          user = User.new(email: params['email'], password: params['password'],
                          password_confirmation: params['password_confirmation'])

          raise ActionController::BadRequest unless user.valid? && user.save

          response.set_cookie(
            :jwt,
            value: generate_token(user), expires: 1.hour.from_now, path: '/', same_site: :none,
            domain: ('.' + request.host), secure: true, httponly: true
          )

          render plain: "Please check your email at #{user.email} to complete your registration", status: 200
        rescue ActionController::BadRequest
          render json: { status: 401, code: 'Invalid credentials', message: user.errors.messages }
        end

        private

          def generate_token(user)
            JWT.encode({ user_id: user.id, exp: (Time.now.utc + 1.hour).to_i }, JWT_SECRET)
          end
      end
    end
  end
end
