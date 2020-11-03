# frozen_string_literal: true
module Hyku
  module API
    module V1
      class ReviewsController < BaseController
        def create
          raise ActionController::BadRequest unless valid_review_action? && perform_review_action

          # For some reason need to switch! the current tenant again
          AccountElevator.switch!(@account.cname)
          sipity_entity = work.to_sipity_entity.reload
          render json: { data: sipity_entity.comments.map { |c| { comment: c.comment, updated_at: c.updated_at, email: c.name_of_commentor } },
                         workflow_status: sipity_entity.workflow_state_name }

        rescue ActionController::BadRequest
          message = 'Unprocessable entity. It has one of the following issues. The user either has no permission to review a work or
            the work does not exists or the action name and comment were not sent back'
          render json: { status: 422, code: 'Unprocessable entity', message: message }
        end

        private

          # Assume one step mediated deposit
          REVIEW_ACTIONS = ['approve', "pending_review", "changes_required", 'comment_only', 'request_changes', 'request_review'].freeze

          def work
            @work ||= ActiveFedora::Base.find(params[:id])
          end

          def valid_review_action?
            params[:name].in?(REVIEW_ACTIONS) && (current_ability.can?(:review, :submissions) || current_ability.can?(:edit, work))
          end

          def perform_review_action
            subject = Hyrax::WorkflowActionInfo.new(work, current_user)
            sipity_workflow_action = PowerConverter.convert_to_sipity_action(params[:name], scope: subject.entity.workflow)
            Hyrax::Workflow::WorkflowActionService.run(subject: subject, action: sipity_workflow_action, comment: params[:comment])
          end
      end
    end
  end
end
