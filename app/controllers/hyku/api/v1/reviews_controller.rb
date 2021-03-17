# frozen_string_literal: true
module Hyku
  module API
    module V1
      class ReviewsController < BaseController
        before_action :check_approval_permissions
        rescue_from ActionController::BadRequest, with: :render_invalid_review

        def create
          raise ActionController::BadRequest unless valid_review_action? && perform_review_action
          # For some reason need to switch! the current tenant again
          AccountElevator.switch!(@account.cname)
          render_work_approval
        end

        def index
          render_work_approval
        end

        private

          # Assume one step mediated deposit
          REVIEW_ACTIONS = ['approve', "pending_review", "changes_required", 'comment_only', 'request_changes', 'request_review'].freeze

          def work
            @work ||= ActiveFedora::Base.find(params[:id])
          end

          def valid_review_action?
            params[:name].in?(REVIEW_ACTIONS)
          end

          def perform_review_action
            subject = Hyrax::WorkflowActionInfo.new(work, current_user)
            sipity_workflow_action = PowerConverter.convert_to_sipity_action(params[:name], scope: subject.entity.workflow)
            Hyrax::Workflow::WorkflowActionService.run(subject: subject, action: sipity_workflow_action, comment: params[:comment])
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
            raise ActionController::BadRequest unless current_ability.can?(:review, :submissions) || current_ability.can?(:edit, work)
          end
      end
    end
  end
end
