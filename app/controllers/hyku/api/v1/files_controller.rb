# frozen_string_literal: true
module Hyku
  module API
    module V1
      class FilesController < BaseController
        include Blacklight::Controller
        include Hydra::Catalog
        include Hydra::Controller::ControllerBehavior

        def index
          @files = work_presenter&.file_set_presenters

          raise Blacklight::Exceptions::RecordNotFound unless @files.present?
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "Work with id of #{params[:id]} has no files attached to it" }
        end

        private

          def work_presenter
            return nil if work_document.nil?
            @work_presenter ||= Hyrax::WorkShowPresenter.new(work_document, current_ability)
          end

          def work_document
            @work_document ||= repository.search(Hyrax::WorkSearchBuilder.new(self).with(params.slice(:id))).documents.first
          end
      end
    end
  end
end
