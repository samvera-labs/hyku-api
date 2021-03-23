# frozen_string_literal: true
module Hyku
  module API
    module V1
      class ReviewsController < BaseController
        rescue_from ActionController::BadRequest, with: :render_invalid_review
        before_action :check_approval_permissions, only: :index

        def create
          raise ActionController::BadRequest unless perform_review_action
          # For some reason need to switch! the current tenant again
          AccountElevator.switch!(@account.cname)
          render_work_approval
        end

        def index
          render_work_approval
        end

        private

          def work
            @work ||= ActiveFedora::Base.find(params[:id])
          end

          def perform_review_action
            Hyrax::Forms::WorkflowActionForm.new(
              current_ability: current_ability,
              work: work,
              attributes: workflow_action_params
            ).save
          end

          def workflow_action_params
            params.permit(:name, :comment)
          end

          def render_work_approval
            sipity_entity = work.to_sipity_entity.reload
            render json: {
              comments: work_comments_collection(sipity_entity).map { |c|
                { comment: c.comment, updated_at: c.updated_at, email: c.name_of_commentor }
              },
              workflow_status: sipity_entity.workflow_state_name
            }
          end

          def work_comments_collection(sipity_entity)
            sipity_entity.comments.page(params[:page] || 1).per(params[:per] || 10).order(updated_at: :desc)
          end

          def render_invalid_review
            message = 'Unprocessable entity. It has one of the following issues. The user either has no permission to review a work or
              the work does not exists or the action name and comment were not sent back'
            render json: { status: 422, code: 'Unprocessable entity', message: message }
          end

          def check_approval_permissions
            raise ActionController::BadRequest unless Hyrax::Workflow::PermissionQuery.scope_permitted_workflow_actions_available_for_current_state(entity: work.to_sipity_entity, user: current_user).any?
          end
      end
    end
  end
end
