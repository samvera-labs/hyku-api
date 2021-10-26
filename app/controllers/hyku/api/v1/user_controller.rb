# frozen_string_literal: true
module Hyku
  module API
    module V1
      class UserController < BaseController
        def show
          @user = User.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: { status: '400', code: 'not_found', message: "Couldn't find User with 'tenant id'=#{params[:id]}" } }
        end
      end
    end
  end
end
