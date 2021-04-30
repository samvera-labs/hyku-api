# frozen_string_literal: true
module Hyku
  module API
    module V1
      class WorkController < BaseController
        include Blacklight::Controller
        include Hydra::Catalog
        include Hydra::Controller::ControllerBehavior

        class_attribute :iiif_manifest_builder
        self.iiif_manifest_builder = (Flipflop.cache_work_iiif_manifest? ? Hyrax::CachingIiifManifestBuilder.new : Hyrax::ManifestBuilderService.new)

        # self.search_builder Hyrax::CollectionSearchBuilder
        configure_blacklight do |config|
          config.search_builder_class = Hyku::API::WorksSearchBuilder
        end

        def index
          super
          raise Blacklight::Exceptions::RecordNotFound if ActiveFedora::Base.where("generic_type_sim:Work").count.zero?
          @works = @document_list.map { |doc| Hyku::WorkShowPresenter.new(doc, current_ability, request) }
          @work_count = @response['response']['numFound']
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: no_result_message }
        end

        def show
          doc = repository.search(single_item_search_builder.query).documents.first
          raise Blacklight::Exceptions::RecordNotFound unless doc.present?
          presenter_class = work_presenter_class(doc)
          @work = presenter_class.new(doc, current_ability, request)
          render json: work_json(@work) and return
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

          def work_json(work)
            {
              uuid: work.id,
              abstract: work.description.first,
              admin_set_name: work.admin_set.first,
              cname: @account.cname,
              contributor: work.contributor,
              creator: work.creator,
              date_submitted: work.date_uploaded,
              files: {
                has_private_files: work.file_set_presenters.any? { |fsp| fsp.solr_document.private? },
                has_registered_files: work.file_set_presenters.any? { |fsp| fsp.solr_document.registered? },
                has_public_files: work.file_set_presenters.any? { |fsp| fsp.solr_document.public? }
              },
              keywords: work.keyword,
              language: work.language,
              license: nil,
              publisher: work.publisher,
              related_url: work.related_url,
              resource_type: work.resource_type,
              rights_statement: work.rights_statement,
              source: work.source,
              subject: work.subject,
              representative_id: work.representative_presenter&.solr_document&.public? ? work.representative_id : nil,
              thumbnail_url: work.thumbnail_presenter&.solr_document&.public? ? build_thumbnail_url(work) : nil,
              title: work.title.first,
              type: "work",
              visibility: work.solr_document.visibility,
              work_type: work.model.model_name.to_s,
              workflow_status: work.solr_document.workflow_state
            }
          end

          def build_thumbnail_url(work)
            components = {
              scheme: Rails.application.routes.default_url_options.fetch(:protocol, 'http'),
              host: @account.cname,
              path: work.solr_document.thumbnail_path.split('?')[0],
              query: work.solr_document.thumbnail_path.split('?')[1]
            }
            URI::Generic.build(components).to_s
          end
      end
    end
  end
end
