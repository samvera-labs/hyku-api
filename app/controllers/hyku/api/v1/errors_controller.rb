# frozen_string_literal: true
module Hyku
  module API
    module V1
      class ErrorsController < Hyku::API::ApplicationController
        def index
          render json: [{ errors: params[:errors] }]
        end
      end
    end
  end
end
