# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::HighlightsController, type: :request, clean: true, multitenant: true do
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

  describe "/highlights" do
    let(:json_response) { JSON.parse(response.body) }

    context 'when repository is empty' do
      it 'returns empty highlights' do
        get "/api/v1/tenant/#{account.tenant}/highlights"
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections' => nil,
                                         'featured_works' => nil,
                                         'recent_works' => nil,
                                         'featured_order' => [])
      end
    end

    context 'when repository has content' do
      let(:collection) { create(:collection, visibility: 'open') }
      let(:work) { create(:work, visibility: 'open') }
      let(:featured_work) { FeaturedWork.create(work_id: work.id) }

      before do
        Apartment::Tenant.switch(account.tenant) do
          collection
          work
          featured_work
        end
      end

      it 'returns explore_collections in highlights' do
        get "/api/v1/tenant/#{account.tenant}/highlights"
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections',
                                         'featured_works',
                                         'recent_works',
                                         'featured_order')
        expect(json_response['explore_collections'].size).to eq 1
        expect(json_response['explore_collections'][0]['uuid']).to eq collection.id
        expect(response).to render_template('hyku/api/v1/collection/_collection')
      end

      it 'returns featured_works in highlights' do
        get "/api/v1/tenant/#{account.tenant}/highlights"
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections',
                                         'featured_works',
                                         'recent_works',
                                         'featured_order')
        expect(json_response['featured_works'].size).to eq 1
        expect(json_response['featured_works'][0]['uuid']).to eq work.id
        expect(response).to render_template('hyku/api/v1/work/_work')
      end

      it 'returns recent_works in highlights' do
        get "/api/v1/tenant/#{account.tenant}/highlights"
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections',
                                         'featured_works',
                                         'recent_works',
                                         'featured_order')
        expect(json_response['recent_works'].size).to eq 1
        expect(json_response['recent_works'][0]['uuid']).to eq work.id
        expect(response).to render_template('hyku/api/v1/work/_work')
      end

      it 'returns featured_order in highlights' do
        get "/api/v1/tenant/#{account.tenant}/highlights"
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections',
                                         'featured_works',
                                         'recent_works',
                                         'featured_order')
        expect(json_response['featured_order'].size).to eq 1
        expect(json_response['featured_order'][0]).to include('id' => featured_work.id,
                                                              'order' => featured_work.order,
                                                              'work_id' => featured_work.work_id,
                                                              'created_at' => featured_work.created_at.as_json,
                                                              'updated_at' => featured_work.updated_at.as_json)
      end
    end

    context 'when not logged in' do
      let(:collection) { create(:collection, visibility: 'restricted') }
      let(:work) { create(:work, visibility: 'restricted') }
      let(:featured_work) { FeaturedWork.create(work_id: work.id) }

      before do
        Apartment::Tenant.switch(account.tenant) do
          collection
          work
          featured_work
        end
      end

      it 'does not return restricted items' do
        get "/api/v1/tenant/#{account.tenant}/highlights"
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections' => nil,
                                         'featured_works' => nil,
                                         'recent_works' => nil,
                                         'featured_order' => Array)
      end
    end

    context 'when logged in' do
      let(:collection) { create(:collection, visibility: 'restricted') }
      let(:work) { create(:work, visibility: 'restricted') }
      let(:featured_work) { FeaturedWork.create(work_id: work.id) }
      let(:user) { create(:admin) }

      before do
        Apartment::Tenant.switch(account.tenant) do
          collection
          work
          featured_work
        end

        post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
          email: user.email,
          password: user.password,
          expire: 2
        }
      end

      it 'returns restricted items' do
        get "/api/v1/tenant/#{account.tenant}/highlights", headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        expect(json_response).to include('explore_collections',
                                         'featured_works',
                                         'recent_works',
                                         'featured_order')
        expect(json_response['explore_collections'].size).to eq 1
        expect(json_response['explore_collections'][0]['uuid']).to eq collection.id
        expect(json_response['featured_works'].size).to eq 1
        expect(json_response['featured_works'][0]['uuid']).to eq work.id
        expect(json_response['recent_works'].size).to eq 1
        expect(json_response['recent_works'][0]['uuid']).to eq work.id
        expect(json_response['featured_order'].size).to eq 1
        expect(json_response['featured_order'][0]).to include('work_id' => featured_work.work_id)
      end
    end
  end
end
