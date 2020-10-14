# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::ErrorsController, type: :request do
  let(:json_response) { JSON.parse(response.body) }

  describe "/errors" do
    it 'echos back the error as JSON' do
      get hyku_api.v1_errors_url, params: { errors: "Test Error" }
      expect(response.status).to eq(200)
      expect(json_response[0]['errors']).to eq "Test Error"
    end
  end
end
