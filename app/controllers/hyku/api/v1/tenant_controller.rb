# frozen_string_literal: true
module Hyku
  module API
    module V1
      class TenantController < Hyku::API::ApplicationController
        def index
          @account = Account.find_by(name: params[:name])
          @accounts = Array(@account)
          if @account.present?
            AccountElevator.switch!(@account.cname)
            @site = Site.instance
            @content_blocks = ContentBlock.all
          end
        end

        def show
          @account = Account.find_by!(tenant: params[:id])
          AccountElevator.switch!(@account.cname)
          @site = Site.instance
          @content_blocks = ContentBlock.all
        rescue ActiveRecord::RecordNotFound
          render json: { error: { status: '400', code: 'not_found', message: "Couldn't find Account with 'tenant uuid'=#{params[:id]}" } }
        end
      end
    end
  end
end
