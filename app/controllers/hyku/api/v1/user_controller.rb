# frozen_string_literal: true
module Hyku
  module API
    module V1
      class UserController < BaseController
        def index
          @users = User.all
        end

        def show
          @user = User.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: { status: '400', code: 'not_found', message: "Couldn't find user with 'id' #{params[:id]}" } }
        end
      end
    end
  end
end
