# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::WorkController, type: :request, clean: true, multitenant: true do
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

  describe "/work" do
    let(:json_response) { JSON.parse(response.body) }

    context "when looking for a registered user" do
      it "returns user JSON" do
        get "/api/v1/tenant/#{account.tenant}/user/#{user.id}"
        expect(response.status).to eq(200)
        expect(json_response['id']).to eq user.id
        expect(response).to render_template('api/v1/user/_user')
      end
    end
  end
end
