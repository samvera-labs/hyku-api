# frozen_string_literal: true
module Hyku
  module API
    module V1
      class UsersController < BaseController
        include Hyku::API::V1::SearchBehavior

        configure_blacklight do |config|
          config.search_builder_class = Hyku::API::WorksSearchBuilder
        end

        def index
          @users = User.all
          @user_count = @users.count
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
