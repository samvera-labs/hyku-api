# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::WorkController, type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:work) { nil }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      user
      work
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/work" do
    let(:json_response) { JSON.parse(response.body) }

    context 'when repository is empty' do
      it 'returns error' do
        get "/api/v1/tenant/#{account.tenant}/work"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => 'This tenant has no works')
      end
    end

    context 'when repository has content' do
      let(:work) { create(:work, visibility: 'open') }

      it 'returns works' do
        get "/api/v1/tenant/#{account.tenant}/work"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 1
        expect(json_response['items'][0]['uuid']).to eq work.id
        expect(response).to render_template('api/v1/work/_work')
      end
    end

    context 'when not logged in' do
      let(:work) { create(:work, visibility: 'restricted') }

      it 'does not return restricted items' do
        get "/api/v1/tenant/#{account.tenant}/work"
        expect(response.status).to eq(200)
        expect(json_response).to include('total' => 0)
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

      it 'returns restricted items' do
        get "/api/v1/tenant/#{account.tenant}/work", headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 1
        expect(json_response['items'][0]['uuid']).to eq work.id
        expect(response).to render_template('api/v1/work/_work')
      end
    end

    context 'with per_page' do
      let(:work1) { create(:work, visibility: 'open') }
      let(:work2) { create(:work, visibility: 'open') }
      let(:per_page) { 1 }

      before do
        Apartment::Tenant.switch(account.tenant) do
          work1
          work2
        end
      end

      it 'limits the number of returned works' do
        get "/api/v1/tenant/#{account.tenant}/work?per_page=#{per_page}"
        expect(response.status).to eq(200)
        expect(json_response['total']).to eq 2
        expect(json_response['items'].size).to eq 1
      end
    end

    context 'when filtering by type' do
      let(:type) { 'image' }
      let(:work1) { nil }
      let(:work2) { nil }

      before do
        Apartment::Tenant.switch(account.tenant) do
          work1
          work2
        end
      end

      context 'when repository is empty' do
        it 'returns error' do
          get "/api/v1/tenant/#{account.tenant}/work?type=#{type}"
          expect(response.status).to eq(200)
          expect(json_response).to include('status' => 404,
                                           'code' => 'not_found',
                                           'message' => 'This tenant has no images')
        end
      end

      context 'when repository has content' do
        let(:work1) { create(:work, visibility: 'open') }
        let(:work2) { Image.create!(visibility: 'open', title: ['Test']) }

        it 'filters works' do
          get "/api/v1/tenant/#{account.tenant}/work?type=#{type}"
          expect(response.status).to eq(200)
          expect(json_response['total']).to eq 1
          expect(json_response['items'][0]['uuid']).to eq work2.id
        end
      end

      context 'when not logged in' do
        let(:work1) { create(:work, visibility: 'restricted') }
        let(:work2) { Image.create!(visibility: 'restricted', title: ['Test']) }

        it 'does not return restricted items' do
          get "/api/v1/tenant/#{account.tenant}/work?type=#{type}"
          expect(response.status).to eq(200)
          expect(json_response).to include('total' => 0)
        end
      end

      context 'when logged in' do
        let(:work1) { create(:work, visibility: 'restricted') }
        let(:work2) { Image.create!(visibility: 'restricted', title: ['Test']) }
        let(:user) { create(:admin) }

        before do
          post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
            email: user.email,
            password: user.password,
            expire: 2
          }
        end

        it 'returns restricted items' do
          get "/api/v1/tenant/#{account.tenant}/work?type=#{type}", headers: { "Cookie" => response['Set-Cookie'] }
          expect(response.status).to eq(200)
          expect(json_response['total']).to eq 1
          expect(json_response['items'][0]['uuid']).to eq work2.id
          expect(response).to render_template('api/v1/work/_work')
        end
      end
    end

    context 'when filtering by metadata' do
      # metadata_fields accepted are: ['creator', 'keyword', 'collection_uuid', 'language', 'availability']
      let(:metadata_field) { 'keyword' }
      let(:metadata_value) { 'cat' }
      let(:work1) { nil }
      let(:work2) { nil }

      before do
        Apartment::Tenant.switch(account.tenant) do
          work1
          work2
        end
      end

      context 'when repository is empty' do
        it 'returns error' do
          get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}"
          expect(response.status).to eq(200)
          expect(json_response).to include('status' => 404,
                                           'code' => 'not_found',
                                           'message' => 'There are no results for this query')
        end
      end

      context 'when repository has content' do
        let(:work1) { create(:work, visibility: 'open') }
        let(:work2) { Image.create!(visibility: 'open', title: ['Test'], keyword: ['cat']) }

        it 'filters works' do
          get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}"
          expect(response.status).to eq(200)
          expect(json_response['total']).to eq 1
          expect(json_response['items'][0]['uuid']).to eq work2.id
        end
      end

      context 'when not logged in' do
        let(:work1) { create(:work, visibility: 'restricted') }
        let(:work2) { Image.create!(visibility: 'restricted', title: ['Test'], keyword: ['cat']) }

        it 'does not return restricted items' do
          get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}"
          expect(response.status).to eq(200)
          expect(json_response).to include('total' => 0)
        end
      end

      context 'when logged in' do
        let(:work1) { create(:work, visibility: 'restricted') }
        let(:work2) { Image.create!(visibility: 'restricted', title: ['Test'], keyword: ['cat']) }
        let(:user) { create(:admin) }

        before do
          post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
            email: user.email,
            password: user.password,
            expire: 2
          }
        end

        it 'returns restricted items' do
          get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}", headers: { "Cookie" => response['Set-Cookie'] }
          expect(response.status).to eq(200)
          expect(json_response['total']).to eq 1
          expect(json_response['items'][0]['uuid']).to eq work2.id
          expect(response).to render_template('api/v1/work/_work')
        end
      end
    end

    # xcontext 'when filtering by file availability' do
    #   # metadata_fields accepted are: ['creator', 'keyword', 'collection_uuid', 'language', 'availability']
    #   let(:metadata_field) { 'availability' }
    #   let(:metadata_value) { 'available' }
    #   let(:work1) { nil }
    #   let(:work2) { nil }

    #   before do
    #     Apartment::Tenant.switch(account.tenant) do
    #       work1
    #       work2
    #     end
    #   end

    #   context 'when repository is empty' do
    #     it 'returns error' do
    #       get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}"
    #       expect(response.status).to eq(200)
    #       expect(json_response).to include('status' => 404,
    #                                        'code' => 'not_found',
    #                                        'message' => 'There are no results for this query')
    #     end
    #   end

    #   context 'when repository has content' do
    #     let(:work1) { create(:work_with_one_file, visibility: 'open') }
    #     let(:work2) { Image.create!(visibility: 'open', title: ['Test']) }
    #     let(:file_set) { work1.file_sets.first }

    #     before do
    #       if file_set.present?
    #         file_set.visibility = work1.visibility
    #         file_set.save!
    #       end
    #     end

    #     it 'filters works' do
    #       get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}"
    #       expect(response.status).to eq(200)
    #       expect(json_response['total']).to eq 1
    #       expect(json_response['items'][0]['uuid']).to eq work1.id
    #     end
    #   end

    #   context 'when not logged in' do
    #     let(:work) { create(:work_with_one_file, visibility: 'restricted') }
    #     let(:file_set) { work.file_sets.first }
    #     let(:metadata_value) { 'not_available' }

    #     before do
    #       if file_set.present?
    #         file_set.visibility = work.visibility
    #         file_set.save!
    #       end
    #     end

    #     it 'does not return restricted items' do
    #       get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}"
    #       expect(response.status).to eq(200)
    #       expect(json_response).to include('total' => 0)
    #     end
    #   end

    #   context 'when logged in' do
    #     let(:work) { create(:work_with_one_file, visibility: 'restricted') }
    #     let(:user) { create(:admin) }
    #     let(:file_set) { work.file_sets.first }
    #     let(:metadata_value) { 'not_available' }

    #     before do
    #       if file_set.present?
    #         file_set.visibility = work.visibility
    #         file_set.save!
    #       end

    #       post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant),  params: {
    #         email: user.email,
    #         password: user.password,
    #         expire: 2
    #       }
    #     end

    #     it 'returns restricted items' do
    #       get "/api/v1/tenant/#{account.tenant}/work?#{metadata_field}=#{metadata_value}", headers: { "Cookie" => response['Set-Cookie'] }
    #       expect(response.status).to eq(200)
    #       expect(json_response['total']).to eq 1
    #       expect(json_response['items'][0]['uuid']).to eq work.id
    #       expect(response).to render_template('api/v1/work/_work')
    #     end
    #   end
    # end
  end

  describe "/work/:id" do
    let(:json_response) { JSON.parse(response.body) }

    context 'with a bad id' do
      it 'returns error' do
        get "/api/v1/tenant/#{account.tenant}/work/bad-id"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => "This is either a private work or there is no record with id: bad-id")
      end
    end

    context 'when repository has content' do
      let(:work) { create(:work, visibility: 'open') }

      it 'returns work json' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}"
        expect(response.status).to eq(200)
        expect(json_response).to include("abstract" => nil,
                                         #  "additional_info" => nil,
                                         #  "additional_links" => nil,
                                         "admin_set_name" => "",
                                         #  "alternative_journal_title" => nil,
                                         #  "alternative_title" => nil,
                                         #  "article_number" => nil,
                                         #  "book_title" => nil,
                                         #  "buy_book" => nil,
                                         #  "challenged" => nil,
                                         "cname" => account.cname,
                                         #  "collections" => nil,
                                         #  "current_he_institution" => nil,
                                         #  "date_accepted" => nil,
                                         #  "date_published" => nil,
                                         "date_submitted" => nil,
                                         #  "degree" => nil,
                                         #  "dewey" => nil,
                                         #  "display" => "full",
                                         #  "doi" => nil,
                                         #  "download_link" => nil,
                                         #  "duration" => nil,
                                         #  "edition" => nil,
                                         #  "eissn" => nil,
                                         #  "event_date" => nil,
                                         #  "event_location" => nil,
                                         #  "event_title" => nil,
                                         "files" => {
                                           "has_private_files" => false,
                                           "has_registered_files" => false,
                                           "has_public_files" => false
                                         },
                                         #  "funder" => nil,
                                         #  "funder_project_reference" => nil,
                                         #  "institution" => nil,
                                         #  "irb_number" => nil,
                                         #  "irb_status" => nil,
                                         #  "is_included_in" => nil,
                                         #  "isbn" => nil,
                                         #  "issn" => nil,
                                         #  "issue" => nil,
                                         #  "journal_title" => nil,
                                         "keywords" => [],
                                         "language" => [],
                                         #  "library_of_congress_classification" => nil,
                                         "license" => nil,
                                         #  "location" => nil,
                                         #  "material_media" => nil,
                                         #  "migration_id" => nil,
                                         #  "official_url" => nil,
                                         #  "organisational_unit" => nil,
                                         #  "outcome" => nil,
                                         #  "page_display_order_number" => nil,
                                         #  "pagination" => nil,
                                         #  "participant" => nil,
                                         #  "photo_caption" => nil,
                                         #  "photo_description" => nil,
                                         #  "place_of_publication" => nil,
                                         #  "project_name" => nil,
                                         "publisher" => [],
                                         #  "qualification_level" => nil,
                                         #  "qualification_name" => nil,
                                         #  "reading_level" => nil,
                                         #  "related_exhibition" => nil,
                                         #  "related_exhibition_date" => nil,
                                         #  "related_exhibition_venue" => nil,
                                         "related_url" => [],
                                         "resource_type" => [],
                                         #  "review_data" => nil,
                                         #  "rights_holder" => nil,
                                         "related_publication_citation" => "Test",
                                         "methodology_collection_method" => "Test",
                                         "programming_language" => "Test",
                                         "attendees" => "Test",
                                         "mentor" => "Test",
                                         "rights_statement" => [],
                                         #  "series_name" => nil,
                                         "source" => [],
                                         "subject" => [],
                                         #  "thumbnail_base64_string" => nil,
                                         "thumbnail_url" => nil,
                                         "title" => "Test title",
                                         "type" => "work",
                                         "uuid" => work.id,
                                         #  "version" => nil,
                                         "visibility" => work.visibility,
                                         #  "volume" => nil,
                                         "work_type" => "GenericWork",
                                         "workflow_status" => nil)
      end

      context 'with files' do
        let(:work) { create(:work, visibility: 'open') }

        context 'thumbnail url' do
          let(:file_with_image) { create(:api_file_set, :public, :image) }

          before do
            work.ordered_members += [file_with_image]
            work.representative_id = file_with_image.id
            work.thumbnail_id = file_with_image.id
            work.save!
            # FIXME: collection.thumbnail_path is still the default work icon due to the file not getting a derivative generated
          end

          it 'returns work json' do
            get "/api/v1/tenant/#{account.tenant}/work/#{work.id}"
            expect(response.status).to eq(200)
            expect(json_response).to include("thumbnail_url" => URI.join("http://#{account.cname}", work.to_solr['thumbnail_path_ss']).to_s)
            expect(json_response).to include("representative_id" => file_with_image.id)
          end
        end

        context 'file visibility' do
          let(:public_file) { create(:file_set, visibility: 'open') }
          let(:institution_file) { create(:file_set, visibility: 'authenticated') }
          let(:private_file) { create(:file_set, visibility: 'restricted') }

          before do
            work.ordered_members += [public_file, institution_file, private_file]
            work.save!
          end

          it 'returns work json' do
            get "/api/v1/tenant/#{account.tenant}/work/#{work.id}"
            expect(response.status).to eq(200)
            expect(json_response["files"]).to include("has_private_files" => true,
                                                      "has_registered_files" => true,
                                                      "has_public_files" => true)
          end
        end
      end
    end

    context 'when not logged in' do
      let(:work) { create(:work, visibility: 'restricted') }

      it 'returns error' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => "This is either a private work or there is no record with id: #{work.id}")
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

      it 'returns work json' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}", headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        expect(json_response['uuid']).to eq work.id
        expect(response).to render_template('hyku/api/v1/work/_work')
      end
    end
  end

  describe '/work/:id/manifest' do
    let(:json_response) { JSON.parse(response.body) }

    context 'with a bad id' do
      it 'returns error' do
        get "/api/v1/tenant/#{account.tenant}/work/bad-id/manifest"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => "This is either a private work or there is no record with id: bad-id")
      end
    end

    context 'when repository has content' do
      let(:work) { create(:work, visibility: 'open') }

      it 'returns IIIF manifest' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/manifest"
        expect(response.status).to eq(200)
        expect(json_response).to include("@context" => "http://iiif.io/api/presentation/2/context.json",
                                         "@id" => "http://www.example.com/concern/generic_works/#{work.id}/manifest")
      end
    end

    context 'when not logged in' do
      let(:work) { create(:work, visibility: 'restricted') }

      it 'returns error' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/manifest"
        expect(response.status).to eq(200)
        expect(json_response).to include('status' => 404,
                                         'code' => 'not_found',
                                         'message' => "This is either a private work or there is no record with id: #{work.id}")
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

      it 'returns IIIF manifest' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/manifest", headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        expect(json_response).to include("@context" => "http://iiif.io/api/presentation/2/context.json",
                                         "@id" => "http://www.example.com/concern/generic_works/#{work.id}/manifest")
      end
    end
  end
end
