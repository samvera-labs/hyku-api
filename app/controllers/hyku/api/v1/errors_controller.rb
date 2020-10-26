# frozen_string_literal: true
module Hyku
  module API
    module V1
      class ErrorsController < BaseController
        def index
          render json: [{ errors: params[:errors] }]
        end
      end
    end
  end
end
