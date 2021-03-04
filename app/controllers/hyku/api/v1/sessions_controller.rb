# frozen_string_literal: true
require 'jwt'

module Hyku
  module API
    module V1
      class SessionsController < BaseController
        skip_before_action :load_token, except: [:destroy, :show]

        def create
          user = User.find_for_database_authentication(email: params[:email])
          raise ActionController::BadRequest unless user&.valid_password?(params[:password])

          set_jwt_cookies(user)
          render_user(user)
        rescue ActionController::BadRequest
          access_denied("Invalid email or password.")
        end

        def destroy
          sign_out(current_user)
          remove_jwt_cookies
          render json: { message: "Successfully logged out" }, status: 200
        end

        def refresh
          if load_token(:refresh)
            set_jwt_cookies(current_user)
            render_user
          else
            remove_jwt_cookies
          end
        end

        def show
          render_user
        end

        private

          def set_jwt_cookies(user)
            set_jwt_cookie(:jwt, value: generate_token(user_id: user.id, type: user_roles(user)), expires: 1.hour.from_now)
            set_jwt_cookie(:refresh, value: generate_token(user_id: user.id), expires: 1.week.from_now)
          end

          def remove_jwt_cookies
            %i[jwt refresh].each do |cookie|
              set_jwt_cookie(cookie, value: '', expires: 10_000.hours.ago)
              cookies[cookie] = nil
            end
          end

          def set_jwt_cookie(name, options)
            response.set_cookie(name, default_cookie_options.merge(options))
          end

          def generate_token(payload = {})
            JWT.encode(payload.merge(exp: (Time.now.utc + 1.hour).to_i), JWT_SECRET)
          end

          def default_cookie_options
            {
              path: '/',
              same_site: :lax,
              domain: ('.' + cookie_domain),
              secure: Rails.env.production?,
              httponly: true
            }
          end

          def cookie_domain
            current_account.attributes.with_indifferent_access[:frontend_url].presence || request.host
          end

          def render_user(user = nil)
            user ||= current_user
            render json: user.slice(:email).merge(participants: user_admin_set_permissions(user), type: user_roles(user))
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
