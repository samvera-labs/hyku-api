# frozen_string_literal: true
module Hyku
  module API
    module V1
      class WorkController < BaseController
        include Hyku::API::V1::SearchBehavior
        # Adds behaviors for hyrax-iiif_av plugin and provides #manifest and #iiif_manifest_builder
        include Hyrax::IiifAv::ControllerBehavior
        include Hyrax::IiifAv::DisplaysIiifAv
        Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::IiifAv::IiifFileSetPresenter

        class_attribute :iiif_manifest_builder
        self.iiif_manifest_builder = (Flipflop.cache_work_iiif_manifest? ? Hyrax::CachingIiifManifestBuilder.new : Hyrax::ManifestBuilderService.new)

        # self.search_builder Hyrax::CollectionSearchBuilder
        configure_blacklight do |config|
          config.search_builder_class = Hyku::API::WorksSearchBuilder
        end

        def index
          super
          raise Blacklight::Exceptions::RecordNotFound if ActiveFedora::Base.where("generic_type_sim:Work").count.zero?

          collection_search_builder = Hyrax::CollectionSearchBuilder.new(self).with_access(:read).rows(1_000_000)
          @collection_docs = repository.search(collection_search_builder).documents
          @works = @document_list.map { |doc| Hyku::WorkShowPresenter.new(doc, current_ability, request) }
          @work_count = @response['response']['numFound']
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: no_result_message }
        end

        def show
          puts 'LOG_presenter ' + presenter.inspect
          doc = repository.search(single_item_search_builder.query).documents.first
          raise Blacklight::Exceptions::RecordNotFound unless doc.present?

          collection_search_builder = Hyrax::CollectionSearchBuilder.new(self).with_access(:read).rows(1_000_000)
          @collection_docs = repository.search(collection_search_builder).documents

          presenter_class = work_presenter_class(doc)
          @work = presenter_class.new(doc, current_ability, request)
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "This is either a private work or there is no record with id: #{params[:id]}" }
        end

        def manifest
          @work = repository.search(single_item_search_builder.query).documents.first
          raise Blacklight::Exceptions::RecordNotFound unless @work.present?

          headers['Access-Control-Allow-Origin'] = '*'
          render json: iiif_manifest_builder.manifest_for(presenter: iiif_manifest_presenter)
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "This is either a private work or there is no record with id: #{params[:id]}" }
        end

        private

          # Instantiates the search builder that builds a query for a single item
          # this is useful in the show view.
          def single_item_search_builder
            Hyrax::WorkSearchBuilder.new(self).with(params.except(:q, :page))
          end

          # Copied and modified from Hyrax WorksControllerBehavior
          def iiif_manifest_builder
            self.class.iiif_manifest_builder
          end

          def iiif_manifest_presenter
            Hyrax::IiifManifestPresenter.new(@work).tap do |p|
              p.hostname = request.hostname
              p.ability = current_ability
            end
          end
          # End copy and modify

          def no_result_message
            return "This tenant has no #{params[:type].pluralize}" if params[:type].present?
            # return "There are no results for this query" if params[:availability].present?

            metadata_params = params.except(:availability, :per_page, :page, :format, :controller, :action, :tenant_id).permit!
            metadata_field, metadata_value = metadata_params.to_h.first
            return "There are no results for this query" if metadata_value.present? && metadata_field.present?

            # default message
            "This tenant has no works"
          end

          def work_presenter_class(doc)
            model_name = doc.to_model.model_name.name
            "Hyrax::#{model_name}Presenter".safe_constantize || Hyku::WorkShowPresenter
          end


          # def work_document
          #   @work_document ||= repository.search(single_item_search_builder.query).documents.first
          # end

          # def authorized_items
          #   return nil if item_member_search_results.nil?
          #   item_member_search_results
          # end

          # def total_items
          #   return 0 if item_member_search_results.nil?
          #   item_member_search_results.count
          # end

        #def item_member_search_results
            # presenter_class = work_presenter_class(work_document)
            #doc = repository.search(single_item_search_builder.query).documents.first
            #work_presenter = work_presenter_class(doc).new(doc, current_ability, request)

            #array_of_ids = work_presenter.list_of_item_ids_to_display
            #members = work_presenter.member_presenters_for(array_of_ids)
            #puts "LOG_members" + members.inspect
            #puts "LOG_array_of_ids" + array_of_ids.inspect
            #@item_member_search_results ||= members
        #end
      end
    end
  end
end
