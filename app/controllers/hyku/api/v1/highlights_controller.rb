# frozen_string_literal: true
module Hyku
  module API
    module V1
      class HighlightsController < BaseController
        include Blacklight::Controller
        include Hydra::Catalog
        include Hydra::Controller::ControllerBehavior

        configure_blacklight do |config|
          config.search_builder_class = Hyrax::HomepageSearchBuilder
        end

        def index
          @collections = collections(rows: 6)
          @recent_documents = recent_documents(rows: 6)
          @featured_works_list = FeaturedWorkList.new.featured_works
          @featured_works = @featured_works_list.select { |fw| current_ability.can? :read, fw.work_id }.map(&:presenter)
          collection_search_builder = Hyrax::CollectionSearchBuilder.new(self).with_access(:read).rows(1_000_000)
          @collection_docs = repository.search(collection_search_builder).documents
        end

        private

          # Copied and modified from hyrax homepage controller
          # Return 5 collections
          def collections(rows: 5)
            builder = Hyrax::CollectionSearchBuilder.new(self)
                                                    .rows(rows)
            response = repository.search(builder)
            response.documents.map { |doc| Hyrax::CollectionPresenter.new(doc, current_ability, request) }
          rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
            []
          end

          def recent_documents(rows: 4)
            # grab any recent documents
            (_, recent_documents) = search_results(q: '', sort: sort_field, rows: rows)
            recent_documents.map { |doc| Hyku::WorkShowPresenter.new(doc, current_ability, request) }
          rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
            []
          end

          def sort_field
            "system_create_dtsi desc"
          end
      end
    end
  end
end
