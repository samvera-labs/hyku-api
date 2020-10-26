# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::FilesController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:work) { create(:work_with_one_file, visibility: 'open') }
  let(:file_set) { work.file_sets.first }
  let(:license) { "http://creativecommons.org/licenses/by-nc/3.0/us/" }
  let(:user) { create(:user) }
  let(:json_response) { JSON.parse(response.body) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      user
      work # force creating the work in the account
      if file_set.present?
        file_set.visibility = work.visibility
        file_set.license = [license]
        file_set.save!
      end
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/files" do
    it 'returns the files of a work' do
      get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/files"
      expect(response.status).to eq(200)
      expect(json_response[0]).to include('uuid' => file_set.id,
                                          'type' => 'file_set',
                                          'name' => file_set.title.first,
                                          'description' => nil,
                                          'mimetype' => file_set.mime_type,
                                          'license' =>  [{ 'name' => 'Attribution-NonCommercial 3.0 United States', 'link' => license }],
                                          'thumbnail_url' => be_a(String), # url
                                          'date_uploaded' => file_set.date_uploaded,
                                          'current_visibility' => file_set.visibility,
                                          'embargo_release_date' => file_set.embargo_release_date,
                                          'lease_expiration_date' => file_set.lease_expiration_date,
                                          'size' => nil,
                                          'download_link' => be_a(String)) # url
    end

    context 'when work does not exist' do
      it 'returns an error' do
        get "/api/v1/tenant/#{account.tenant}/work/bad-id/files"
        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(404)
        expect(json_response['code']).to eq('not_found')
        expect(json_response['message']).to eq "Work with id of bad-id has no files attached to it"
      end
    end

    context 'when work has no files' do
      let!(:work) { create(:work, visibility: 'open') }

      it 'returns an error' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/files"
        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(404)
        expect(json_response['code']).to eq('not_found')
        expect(json_response['message']).to eq "Work with id of #{work.id} has no files attached to it"
      end
    end

    context 'when not logged in' do
      let!(:work) { create(:work_with_one_file, visibility: 'restricted') }

      it 'does not return files for restricted works' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/files"
        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(404)
        expect(json_response['code']).to eq('not_found')
        expect(json_response['message']).to eq "Work with id of #{work.id} has no files attached to it"
      end
    end

    context 'when logged in' do
      let(:work) { create(:work_with_one_file, visibility: 'restricted') }
      let(:user) { create(:admin) }

      before do
        post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
          email: user.email,
          password: user.password,
          expire: 2
        }
      end

      it 'returns restricted items' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/files", headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        expect(json_response[0]).to include('uuid' => file_set.id)
      end
    end
  end
end
