# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyku::API::V1::ReviewsController, type: :request, clean: true, multitenant: true do
  let(:depositing_user) { create(:user) }
  let(:approving_user) { create(:user) }
  let(:account) { create(:account) }
  let(:admin_set) { create(:admin_set, with_permission_template: true) }
  let(:permission_template_access) do
    create(:permission_template_access,
           :manage,
           permission_template: admin_set.permission_template,
           agent_type: 'user',
           agent_id: approving_user.user_key)
  end
  let(:work) { create(:work, user: depositing_user, admin_set_id: admin_set.id) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      permission_template_access
      Hyrax::Workflow::WorkflowImporter.load_workflow_for(permission_template: admin_set.permission_template)
      workflow = admin_set.permission_template.available_workflows.find_by(name: 'one_step_mediated_deposit')
      Sipity::Workflow.activate!(permission_template: admin_set.permission_template, workflow_id: workflow.id)
      Hyrax::Workflow::PermissionGenerator.call(roles: 'approving', workflow: workflow, agents: approving_user)
      # Need to instantiate the Sipity::Entity for the given work. This is necessary as I'm not creating the work via the UI.
      Sipity::Entity.create!(proxy_for_global_id: work.to_global_id.to_s,
                             workflow: work.active_workflow,
                             workflow_state: PowerConverter.convert_to_sipity_workflow_state('pending_review', scope: workflow))
      post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
        email: user.email,
        password: user.password,
        expire: 2
      }
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/reviews" do
    context 'with proper privileges' do
      let(:user) { approving_user }

      it "adds comment" do
        Apartment::Tenant.switch(account.tenant) do
          expect do
            post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
              name: "comment_only",
              comment: "can manage workflow from api"
            }, headers: { "Cookie" => response['Set-Cookie'] }
          end.to change { work.reload.to_sipity_entity.comments.count }.by(1)
          expect(work.reload.to_sipity_entity.comments.count).to eq 1
          expect(response.status).to eq(200)
          json_response = JSON.parse(response.body)
          expect(json_response['comments'][0]['comment']).to be_present
          expect(json_response['comments'][0]['updated_at']).to be_present
          expect(json_response['workflow_status']).to eq 'pending_review'
        end
      end

      it 'changes state' do
        Apartment::Tenant.switch(account.tenant) do
          expect do
            post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
              name: "approve",
              comment: "can manage workflow from api"
            }, headers: { "Cookie" => response['Set-Cookie'] }
          end.to change { work.to_sipity_entity.reload.workflow_state_name }.from("pending_review").to("deposited")

          expect(response.status).to eq(200)
          json_response = JSON.parse(response.body)
          expect(json_response['comments'][0]['comment']).to be_present
          expect(json_response['comments'][0]['updated_at']).to be_present
          expect(json_response['workflow_status']).to eq 'deposited'
        end
      end
    end

    context 'without proper privileges' do
      let(:user) { create(:user) }

      it 'returns an error json doc' do
        post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
          name: "approve",
          comment: "can manage workflow from api"
        }, headers: { "Cookie" => response['Set-Cookie'] }

        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(422)
        expect(json_response['code']).to eq "Unprocessable entity"
        expect(json_response['code']).to be_present
      end
    end
  end

  describe "/index" do
    context 'for an approving user' do
      let(:user) { approving_user }

      it "returns the workflow status" do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
          page: 2,
          per_page: 1
        }, headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['workflow_status']).to eq 'pending_review'
      end

      context 'with some comments' do
        before do
          jwt_cookie = response['Set-Cookie']
          post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
            name: "comment_only",
            comment: "you can do better!"
          }, headers: { "Cookie" => jwt_cookie }
          post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
            name: "approve",
            comment: "well done!"
          }, headers: { "Cookie" => jwt_cookie }
          get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
            page: 2,
            per_page: 1
          }, headers: { "Cookie" => jwt_cookie }
        end

        it "renders the workflow state" do
          expect(response.status).to eq(200)
          json_response = JSON.parse(response.body)
          expect(json_response['comments'][0]['comment']).to be_present
          expect(json_response['comments'][0]['updated_at']).to be_present
          expect(json_response['workflow_status']).to eq 'deposited'
        end

        it 'paginates and orders the response comments' do
          json_response = JSON.parse(response.body)
          expect(json_response['comments'].count).to eq 1
          expect(json_response['comments'][0]['comment']).to eq 'you can do better!'
          expect(json_response['page']).to eq 2
          expect(json_response['total_comments']).to eq 2
        end
      end
    end

    context 'for an depositing user' do
      let(:user) { depositing_user }

      it "returns the workflow status" do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
          page: 2,
          per_page: 1
        }, headers: { "Cookie" => response['Set-Cookie'] }
        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['workflow_status']).to be_blank
      end
    end

    context 'without proper privileges' do
      let(:user) { create(:user) }

      it 'returns an error json doc' do
        get "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {}, headers: { "Cookie" => response['Set-Cookie'] }

        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(422)
        expect(json_response['code']).to eq "Unprocessable entity"
        expect(json_response['code']).to be_present
      end
    end
  end
end
