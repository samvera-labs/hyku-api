# frozen_string_literal: true
module Hyku
  module API
    module V1
      class CollectionController < Hyku::API::ApplicationController
        include Blacklight::Controller
        include Hydra::Catalog
        include Hydra::Controller::ControllerBehavior

        # self.search_builder Hyrax::CollectionSearchBuilder
        configure_blacklight do |config|
          config.search_builder_class = Hyrax::CollectionSearchBuilder
        end

        def index
          super
          raise ActiveRecord::RecordNotFound if Collection.count.zero?
          @collections = @document_list
          @collection_count = @response['response']['numFound']
        rescue ActiveRecord::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "This tenant has no collection" }
        end

        def show
          @collection = repository.search(single_item_search_builder.query).documents.first
          raise Blacklight::Exceptions::RecordNotFound unless @collection.present?
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "This is either a private collection or there is no record with id: #{params[:id]}" }
        end

        private

          # Instantiates the search builder that builds a query for a single item
          # this is useful in the show view.
          def single_item_search_builder
            Hyrax::SingleCollectionSearchBuilder.new(self).with(params.except(:q, :page))
          end
      end
    end
  end
end
