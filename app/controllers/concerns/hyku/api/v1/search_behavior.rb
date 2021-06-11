# frozen_string_literal: true
module Hyku
  module API
    module V1
      module SearchBehavior
        extend ActiveSupport::Concern

        include Blacklight::Controller
        include Hydra::Catalog
        include Hydra::Controller::ControllerBehavior

        protected

          # Override of Blacklight method to handle exception on redirect
          # when The index throws an error (Blacklight::Exceptions::InvalidRequest), this method is executed.
          def handle_request_error(exception)
            # rubocop:disable Style/GuardClause
            if Rails.env.development? || Rails.env.test?
              raise exception # Rails own code will catch and give usual Rails error page with stack trace
            else

              flash_notice = I18n.t('blacklight.search.errors.request_error')

              # If there are errors coming from the index page, we want to trap those sensibly

              if flash[:notice] == flash_notice
                logger.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
                raise exception
              end

              logger.error exception

              # Return json instead of redirect to root_path
              render(json: { status: 500, code: 'Search error', message: flash_notice }, status: 500)
            end
            # rubocop:enable Style/GuardClause
          end
      end
    end
  end
end
