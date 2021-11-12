# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::UserController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      user
      user2
      user3
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/user" do
    let(:json_response) { JSON.parse(response.body) }

    context "when there are registered users" do
      it "returns a list of all users" do
        get "/api/v1/tenant/#{account.tenant}/user"
        expect(json_response['total']).to eq(3)
        expect(json_response['items']).to include(a_hash_including("id"=> user.id))
        expect(json_response['items']).to include(a_hash_including("id"=> user2.id))
        expect(json_response['items']).to include(a_hash_including("id"=> user3.id))
      end
      it "returns user JSON when a user is found" do
        get "/api/v1/tenant/#{account.tenant}/user/#{user.id}"
        expect(response.status).to eq(200)
        expect(json_response['id']).to eq user.id
        expect(response).to render_template('api/v1/user/_user')
      end
    end

      context "when there are no registered users" do
        it "returns error when there is no user" do
          get "/api/v1/tenant/#{account.tenant}/user/#{user.id + 42}"
          expect(json_response['error']).to include('message' => "Couldn't find user with 'id' #{user.id + 42}")
        end
    end
  end
end
