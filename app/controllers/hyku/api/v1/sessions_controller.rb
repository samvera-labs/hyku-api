# frozen_string_literal: true
require 'jwt'

module Hyku
  module API
    module V1
      class SessionsController < Hyku::API::ApplicationController
        def create
          user = User.find_for_database_authentication(email: params[:email])
          raise ActionController::BadRequest unless user&.valid_password?(params[:password])

          response.set_cookie(
            :jwt,
            value: generate_token(user), expires: 1.hour.from_now, path: '/', same_site: :none,
            domain: ('.' + request.host), secure: true, httponly: true
          )

          render json: user.slice(:email).merge(participants: user_admin_set_permissions(user), type: user_roles(user))
        rescue ActionController::BadRequest
          render json: { status: 401, code: 'Invalid credentials', message: "Invalid email or password." }
        end

        def destroy
          sign_out(current_user)
          response.set_cookie(
            :jwt,
            value: '', expires: 10000.hours.ago, path: '/', same_site: :none,
            domain: ('.' + request.host), secure: true, httponly: true
          )

          render json: {message: "Successfully logged out"}, status: 200
        end

        def refresh
          raise ActionController::BadRequest unless current_user

          response.set_cookie(
            :jwt,
            value: generate_token(current_user), expires: 1.hour.from_now, path: '/', same_site: :none,
            domain: ('.' + request.host), secure: true, httponly: true
          )

          render json: current_user.slice(:email).merge(participants: user_admin_set_permissions(current_user), type: user_roles(current_user))
        rescue ActionController::BadRequest
          render json: { status: 401, code: 'Invalid credentials', message: "Invalid email or password." }
        end

        private

          def generate_token(user)
            JWT.encode({ user_id: user.id, exp: (Time.now.utc + 1.hour).to_i }, JWT_SECRET)
          end

          def user_roles(user)
            # Need to call `.uniq` because admin role can appear twice
            user.roles.map(&:name).uniq - ['super_admin']
          end

          def user_admin_set_permissions(user)
            Hyrax::PermissionTemplateAccess.where(agent_id: user.user_key).collect do |pta|
              { pta.permission_template.admin_set&.title&.first => pta.access }
            end
          end
      end
    end
  end
end
