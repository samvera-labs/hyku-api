# frozen_string_literal: true
module Hyku
  module API
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      before_action do
        @account = Account.find_by(tenant: params[:tenant_id])
        AccountElevator.switch!(@account.cname) if @account.present?
      end
    end
  end
end
