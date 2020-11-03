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
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  describe "/reviews" do
    context 'with proper privileges' do
      before do
        post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
          email: approving_user.email,
          password: approving_user.password,
          expire: 2
        }
      end

      it "adds comment" do
        expect do
          post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
            name: "comment_only",
            comment: "can manage workflow from api"
          }, headers: { "Cookie" => response['Set-Cookie'] }
        end.to change { work.to_sipity_entity.comments.count }.by(1)

        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['data'][0]['comment']).to be_present
        expect(json_response['data'][0]['updated_at']).to be_present
        expect(json_response['workflow_status']).to eq 'pending_review'
      end

      it 'changes state' do
        expect do
          post "/api/v1/tenant/#{account.tenant}/work/#{work.id}/reviews", params: {
            name: "approve",
            comment: "can manage workflow from api"
          }, headers: { "Cookie" => response['Set-Cookie'] }
        end.to change { work.to_sipity_entity.reload.workflow_state_name }.from("pending_review").to("deposited")

        expect(response.status).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['data'][0]['comment']).to be_present
        expect(json_response['data'][0]['updated_at']).to be_present
        expect(json_response['workflow_status']).to eq 'deposited'
      end
    end

    context 'without proper privileges' do
      let(:end_user) { create(:user) }

      before do
        Apartment::Tenant.switch(account.tenant) { end_user }
        post hyku_api.v1_tenant_users_login_path(tenant_id: account.tenant), params: {
          email: end_user.email,
          password: end_user.password,
          expire: 2
        }
      end

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
end
