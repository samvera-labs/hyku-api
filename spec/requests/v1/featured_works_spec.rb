# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::FeaturedWorksController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:work) { create(:work, visibility: 'open') }
  let(:json_response) { JSON.parse(response.body) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      work # force creating the work in the account
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "POST /featured_works" do
    it 'features a work' do
      expect do
        post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/featured_works", params: { order: 1 }
      end.to change { Apartment::Tenant.switch(account.tenant) { FeaturedWork.count } }.by(1)
      expect(response.status).to eq(200)
      expect(json_response['code']).to eq(201)
      expect(json_response['status']).to eq 'created'
    end

    context 'when required parameter is missing' do
      it 'does not feature the work' do
        expect do
          post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/featured_works", params: {}
        end.not_to change { Apartment::Tenant.switch(account.tenant) { FeaturedWork.count } }
        expect(response.status).to eq(422)
        expect(json_response).to eq("order" => ["is not included in the list"])
      end
    end
  end

  describe "DELETE /featured_works" do
    let(:featured_work) { FeaturedWork.create(work_id: work.id, order: 1) }

    before do
      Apartment::Tenant.switch(account.tenant) { featured_work }
    end

    it 'removes feature of a work' do
      expect do
        delete "/api/v1/tenant/#{account.tenant}/work/#{work.id}/featured_works"
      end.to change { Apartment::Tenant.switch(account.tenant) { FeaturedWork.count } }.by(-1)
      expect(FeaturedWork.exists?(featured_work.id)).to eq false
      expect(response.status).to eq(204)
      expect(response.body).to be_blank
    end
  end
end
