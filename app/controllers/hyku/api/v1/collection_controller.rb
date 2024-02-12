# frozen_string_literal: true
module Hyku
  module API
    module V1
      class CollectionController < BaseController
        include Hyku::API::V1::SearchBehavior

        # self.search_builder Hyrax::CollectionSearchBuilder
        configure_blacklight do |config|
          config.search_builder_class = Hyrax::CollectionSearchBuilder
        end

        def index
          super
          raise Blacklight::Exceptions::RecordNotFound if Collection.count.zero?

          @collections = @document_list.map { |doc| Hyrax::CollectionPresenter.new(doc, current_ability, request) }
          @collection_count = @response['response']['numFound']
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "This tenant has no collection" }
        end

        def show
          @collection = collection_presenter
          raise Blacklight::Exceptions::RecordNotFound unless @collection.present?

          @available_parent_collections = authorized_parent_collection_presenters
          @total_parent_collections = total_authorized_parent_collections
          @child_collections = authorized_sub_collection_presenters
          @total_child_collections = total_authorized_sub_collections
          @works = authorized_work_presenters
          @total_works = total_authorized_works
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "This is either a private collection or there is no record with id: #{params[:id]}" }
        end

        private

        #-------------------- Parent collections ------------------------------------

        def authorized_parent_collection_presenters
          return nil if collection_presenter.nil?
          parent_collections = parent_collection_search_results
          puts "LOG_parent_collections" + parent_collections.inspect
          @available_parent_collections = parent_collections.map do |col|
            { "id" => col.id, "title_first" => col.title.first }
          end.to_json
        end

        def total_authorized_parent_collections
          return 0 if collection_presenter.nil?
          parent_collection_search_results.count
        end

        def parent_collection_search_results
          @parent_collection_search_results ||=
            Hyrax::Collections::NestedCollectionQueryService.available_parent_collections(child: collection_presenter, scope: self, limit_to_id: nil)
        end

        #-------------------- Child collections ------------------------------------
        def authorized_sub_collection_presenters
          return nil if collection_presenter.nil?
          sub_collection_documents = collection_sub_collection_search_results.documents
          puts "LOG_sub_collection_documents" + sub_collection_documents.inspect
          sub_collection_documents.map do |doc|
            Hyrax::CollectionPresenter.new(doc, current_ability, request)
          end
        end

        def total_authorized_sub_collections
          return 0 if collection_presenter.nil?
          collection_sub_collection_search_results.total
        end

        def collection_sub_collection_search_results
          @collection_sub_collection_search_results ||=
            if class_exists?('CollectionMemberSearchService')
              Hyrax::Collections::CollectionMemberSearchService.new(scope: self, collection: collection_presenter, params: params).available_member_subcollections
            else
              Hyrax::Collections::CollectionMemberService.new(scope: self, collection: collection_presenter, params: params).available_member_subcollections
            end
        end

        #-------------------- Work collections ------------------------------------
        def authorized_work_presenters
          return nil if collection_presenter.nil?
          work_documents = collection_member_search_results.documents
          work_documents.map do |doc|
            presenter_class = work_presenter_class(doc)
            presenter_class.new(doc, current_ability, request)
          end
        end

        def total_authorized_works
          return 0 if collection_presenter.nil?
          collection_member_search_results.total
        end

        def collection_member_search_results
          @collection_member_search_results ||=
            if class_exists?('CollectionMemberSearchService')
              Hyrax::Collections::CollectionMemberSearchService.new(scope: self, collection: collection_presenter, params: params).available_member_works
            else
              Hyrax::Collections::CollectionMemberService.new(scope: self, collection: collection_presenter, params: params).available_member_works
            end
        end

        def class_exists?(class_name)
          klass = Hyrax::Collections.const_get(class_name)
          klass.is_a?(Class)
        rescue NameError
          false
        end

        def collection_presenter
          return nil if collection_document.nil?
          @collection_presenter ||= Hyrax::CollectionPresenter.new(collection_document, current_ability, request)
        end

        def collection_document
          @collection_document ||= repository.search(single_item_search_builder.query).documents.first
        end

        # Instantiates the search builder that builds a query for a single item
        # this is useful in the show view.
        def single_item_search_builder
          Hyrax::SingleCollectionSearchBuilder.new(self).with(params.except(:q, :page))
        end

        def work_presenter_class(doc)
          model_name = doc.to_model.model_name.name
          "Hyrax::#{model_name}Presenter".safe_constantize || Hyku::WorkShowPresenter
        end
      end
    end
  end
end
