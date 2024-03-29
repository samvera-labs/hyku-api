# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::SearchController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:work) { nil }
  let(:collection) { nil }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      user
      work
      collection
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/search" do
    let(:json_response) { JSON.parse(response.body) }
    let(:search_q) { '' }
    let(:search_f) { '' }

    context 'when repository is empty' do
      it 'returns error' do
        get "/api/v1/tenant/#{account.tenant}/search"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => "No record found for query_term: #{search_q} and filters containing #{search_f}")
      end
    end

    context 'when repository has content' do
      let(:collection) { create(:collection, visibility: 'open') }
      let(:work) { create(:work, visibility: 'open') }

      it 'returns collection and work results' do
        get "/api/v1/tenant/#{account.tenant}/search"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 2
        expect(json_response['items']).to include(hash_including('uuid' => collection.id),
                                                  hash_including('uuid' => work.id))
        expect(json_response['facet_counts']).to be_present
      end
    end

    context 'when not logged in' do
      let(:work) { create(:work, visibility: 'restricted') }

      it 'does not return restricted results' do
        get "/api/v1/tenant/#{account.tenant}/search"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => "No record found for query_term: #{search_q} and filters containing #{search_f}")
      end
    end

    context 'when logged in' do
      let(:work) { create(:work, visibility: 'restricted') }
      let(:user) { create(:admin) }

      before do
        post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
          email: user.email,
          password: user.password,
          expire: 2
        }
      end

      it 'returns restricted results' do
        get "/api/v1/tenant/#{account.tenant}/search", headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 1
        expect(json_response['items'][0]['uuid']).to eq work.id
        expect(json_response['facet_counts']).to be_present
      end
    end

    context 'with q' do
      let(:work) { create(:work, visibility: 'open', title: ['Cat']) }
      let(:work2) { create(:work, visibility: 'open', title: ['Dog']) }

      before do
        Apartment::Tenant.switch(account.tenant) { work2 }
      end

      it 'filters work results' do
        get "/api/v1/tenant/#{account.tenant}/search?q=cat"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 1
        expect(json_response['items'][0]['uuid']).to eq work.id
        expect(json_response['facet_counts']).to be_present
        expect(response).to render_template('api/v1/work/_work')
      end
    end

    context 'with f' do
      let(:collection) { create(:collection, visibility: 'open') }
      let(:work) { create(:work, visibility: 'open') }

      it 'filters work results' do
        get "/api/v1/tenant/#{account.tenant}/search?f[human_readable_type_sim][]=Work"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 1
        expect(json_response['items'][0]['uuid']).to eq work.id
        expect(json_response['facet_counts']).to be_present
        expect(response).to render_template('hyku/api/v1/work/_work')
      end

      it 'filters collection results' do
        get "/api/v1/tenant/#{account.tenant}/search?f[human_readable_type_sim][]=Collection"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 1
        expect(json_response['items'][0]['uuid']).to eq collection.id
        expect(json_response['facet_counts']).to be_present
        expect(response).to render_template('hyku/api/v1/collection/_collection')
      end
    end

    context 'with sort' do
      let(:work) { create(:work, visibility: 'open', date_uploaded: '1996') }
      let(:work2) { create(:work, visibility: 'open', date_uploaded: '1990') }
      let(:sort) { 'date_uploaded_ssi asc' }

      before do
        Apartment::Tenant.switch(account.tenant) { work2 }
      end

      it 'sorts results' do
        get "/api/v1/tenant/#{account.tenant}/search?sort=#{sort}"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 2
        expect(json_response['items'][0]['uuid']).to eq work2.id
        expect(json_response['items'][1]['uuid']).to eq work.id
        expect(json_response['facet_counts']).to be_present
      end
    end

    context 'with per_page' do
      let(:work) { create(:work, visibility: 'open', date_uploaded: '1996') }
      let(:work2) { create(:work, visibility: 'open', date_uploaded: '1990') }
      let(:per_page) { 1 }
      let(:sort) { 'date_uploaded_ssi desc' }

      before do
        Apartment::Tenant.switch(account.tenant) { work2 }
      end

      it 'limits the number of results' do
        get "/api/v1/tenant/#{account.tenant}/search?per_page=#{per_page}&sort=#{sort}"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 2
        expect(json_response['items'].size).to eq 1
        expect(json_response['items'][0]['uuid']).to eq work.id
        expect(json_response['facet_counts']).to be_present
      end

      context 'with page' do
        let(:page) { 2 }

        it 'limits the number of results and offsets to page' do
          get "/api/v1/tenant/#{account.tenant}/search?per_page=#{per_page}&page=#{page}&sort=#{sort}"
          expect(response.status).to eq(200)
          expect(json_response['total']).to eq 2
          expect(json_response['items'].size).to eq 1
          expect(json_response['items'][0]['uuid']).to eq work2.id
          expect(json_response['facet_counts']).to be_present
        end
      end
    end

    context 'when solr throws an exception' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow_any_instance_of(Hyku::API::V1::SearchController).to receive(:search_results).and_raise(Blacklight::Exceptions::InvalidRequest)
      end

      it 'returns json 500' do
        get "/api/v1/tenant/#{account.tenant}/search"
        expect(response.status).to eq(500)
        expect(json_response['message']).to be_present
        expect(json_response['code']).to eq 'Search error'
        expect(json_response['status']).to eq 500
      end
    end
  end

  describe "/search/facet/:id" do
    let(:json_response) { JSON.parse(response.body) }

    context 'all facets' do
      let(:work) { create(:work, visibility: 'open', keyword: ['testb'], language: ['English']) }
      let(:another_work) { create(:work, visibility: 'open', keyword: ['testa', 'testb'], language: ['Basque']) }
      let(:id) { 'all' }

      before do
        Apartment::Tenant.switch(account.tenant) { another_work }
      end

      it 'returns facet information' do
        get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}"
        expect(response.status).to eq(200)
        expect(json_response).to include('keyword_sim' => { "testb" => 2, "testa" => 1 },
                                         'language_sim' => { "English" => 1, "Basque" => 1 },
                                         'human_readable_type_sim' => { "Work" => 2 },
                                         'resource_type_sim' => {},
                                         'member_of_collections_ssim' => {})
      end

      it "returns the result ordered by hits" do
        get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}"
        expect(response.status).to eq(200)
        expect(json_response['keyword_sim'].to_a).to eq({ "testb" => 2, "testa" => 1 }.to_a)
      end

      context 'with many facet values' do
        let(:work) { create(:work, visibility: 'open', keyword: ['testc', 'testd', 'teste', 'testf', 'testg', 'testh', 'testi', 'testj', 'testk']) }

        it 'returns all facet value counts without pagination' do
          get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}"
          expect(response.status).to eq(200)
          expect(json_response).to include('keyword_sim' => { "testa" => 1,
                                                              "testb" => 1,
                                                              "testc" => 1,
                                                              "testd" => 1,
                                                              "teste" => 1,
                                                              "testf" => 1,
                                                              "testg" => 1,
                                                              "testh" => 1,
                                                              "testi" => 1,
                                                              "testj" => 1,
                                                              "testk" => 1 })
        end
      end

      context 'with q' do
        let(:work) { create(:work, visibility: 'open', keyword: ['Cat'], language: ["English"]) }
        let(:work2) { create(:work, visibility: 'open', keyword: ['Dog'], language: ["French"]) }
        let(:q) { 'cat' }

        before do
          Apartment::Tenant.switch(account.tenant) { work2 }
        end

        it 'returns facet information' do
          get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}?q=#{q}"
          expect(response.status).to eq(200)
          expect(json_response).to include('keyword_sim' => { "Cat" => 1 },
                                           'language_sim' => { "English" => 1 },
                                           'human_readable_type_sim' => { "Work" => 1 },
                                           'resource_type_sim' => {},
                                           'member_of_collections_ssim' => {})
        end
      end

      context 'with f' do
        let(:work) { create(:work, visibility: 'open', keyword: ['Cat'], language: ["English"]) }
        let(:work2) { create(:work, visibility: 'open', keyword: ['Dog'], language: ["French"]) }
        let(:f) { 'Cat' }

        before do
          Apartment::Tenant.switch(account.tenant) { work2 }
        end

        it 'filters results' do
          get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}?f[keyword_sim][]=#{f}"
          expect(response.status).to eq(200)
          expect(json_response).to include('keyword_sim' => { "Cat" => 1 },
                                           'language_sim' => { "English" => 1 },
                                           'human_readable_type_sim' => { "Work" => 1 },
                                           'resource_type_sim' => {},
                                           'member_of_collections_ssim' => {})
        end
      end
    end

    context 'single facet' do
      let(:work) { create(:work, visibility: 'open', keyword: ['Cat']) }
      let(:id) { 'keyword_sim' }

      it 'returns facet information' do
        get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}"
        expect(response.status).to eq(200)
        expect(json_response).to eq("Cat" => 1)
      end

      context 'with q' do
        let(:work2) { create(:work, visibility: 'open', keyword: ['Dog']) }
        let(:id) { 'keyword_sim' }
        let(:q) { 'cat' }

        before do
          Apartment::Tenant.switch(account.tenant) { work2 }
        end

        it 'filters work results' do
          get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}?q=#{q}"
          expect(response.status).to eq(200)
          expect(json_response).to eq("Cat" => 1)
        end
      end

      context 'with f' do
        let(:work2) { create(:work, visibility: 'open', keyword: ['Dog']) }
        let(:id) { 'keyword_sim' }
        let(:f) { 'Dog' }

        before do
          Apartment::Tenant.switch(account.tenant) { work2 }
        end

        it 'filters results' do
          get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}?f[keyword_sim][]=#{f}"
          expect(response.status).to eq(200)
          expect(json_response).to eq("Dog" => 1)
        end
      end

      context 'with per_page' do
        let(:work2) { create(:work, visibility: 'open', keyword: ['Cat']) }
        let(:work3) { create(:work, visibility: 'open', keyword: ['Dog']) }
        let(:per_page) { 1 }
        let(:id) { 'keyword_sim' }

        before do
          Apartment::Tenant.switch(account.tenant) do
            work2
            work3
          end
        end

        it 'limits the number of facet results' do
          get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}?per_page=#{per_page}"
          expect(response.status).to eq(200)
          expect(json_response.size).to eq 1
          expect(json_response).to eq("Cat" => 2)
        end

        context 'with page' do
          let(:page) { 2 }

          it 'limits the number of facet results and offsets to page' do
            get "/api/v1/tenant/#{account.tenant}/search/facet/#{id}?per_page=#{per_page}&page=#{page}"
            expect(response.status).to eq(200)
            expect(json_response.size).to eq 1
            expect(json_response).to eq("Dog" => 1)
          end
        end
      end
    end
  end
end
