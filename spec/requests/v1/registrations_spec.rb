# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::RegistrationsController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:email) { 'user@example.com' }
  let(:password) { 'secure_password' }
  let(:json_response) { JSON.parse(response.body) }
  let(:jwt_cookie) { response.cookies.with_indifferent_access[:jwt] }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) { Site.update(account: account) }
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/signup" do
    it 'registers the user' do
      post hyku_api.v1_tenant_users_signup_url(tenant_id: account.id), params: { email: email, password: password, password_confirmation: password }

      expect(response.status).to eq(200)
      expect(response.body).to eq "Please check your email at #{email} to complete your registration"
      expect(jwt_cookie).to be_truthy
    end

    xcontext 'when email does not have correct domain' do
      let(:domain) { 'example.com' }
      let(:email) { 'user@test.com' }

      it 'does not register the user' do
        post hyku_api.v1_tenant_users_signup_url(tenant_id: account.id), params: { email: email, password: password, password_confirmation: password }

        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(401)
        expect(json_response['code']).to eq 'Invalid credentials'
        expect(json_response['message']).to include("email" => ["Email must contain #{domain}"])
        expect(jwt_cookie).to be_falsey
      end
    end

    context 'when email is already registered' do
      before do
        post hyku_api.v1_tenant_users_signup_url(tenant_id: account.id), params: { email: email, password: password, password_confirmation: password }
      end

      it 'does not register the user' do
        post hyku_api.v1_tenant_users_signup_url(tenant_id: account.id), params: { email: email, password: password, password_confirmation: password }

        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(401)
        expect(json_response['code']).to eq 'Invalid credentials'
        expect(json_response['message']).to include("email" => ["has already been taken"])
        expect(jwt_cookie).to be_falsey
      end
    end

    context 'when password confirmation does not match password' do
      it 'does not register the user' do
        post hyku_api.v1_tenant_users_signup_url(tenant_id: account.id), params: { email: email, password: password, password_confirmation: 'different password' }

        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(401)
        expect(json_response['code']).to eq 'Invalid credentials'
        expect(json_response['message']).to include("password_confirmation" => ["doesn't match Password"])
        expect(jwt_cookie).to be_falsey
      end
    end
  end
end
