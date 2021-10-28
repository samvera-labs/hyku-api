# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::UserController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      user
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/user" do
    let(:json_response) { JSON.parse(response.body) }

    context "when looking for a registered user" do
      it "returns user JSON when a user is found" do
        get "/api/v1/tenant/#{account.tenant}/user/#{user.id}"
        expect(response.status).to eq(200)
        expect(json_response['id']).to eq user.id
        expect(response).to render_template('api/v1/user/_user')
      end

      it "returns error when there is no user" do
        get "/api/v1/tenant/#{account.tenant}/user/#{user.id + 1}"
        expect(json_response).to include('message' => "Couldn't find user with 'id' #{user.id + 1}")
      end
    end
  end
end
