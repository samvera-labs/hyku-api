# frozen_string_literal: true
module Hyku
  module API
    module V1
      class SearchController < BaseController
        include Blacklight::Controller
        include Hydra::Catalog
        include Hydra::Controller::ControllerBehavior

        include Blacklight::Configurable
        copy_blacklight_config_from(::CatalogController)

        def index
          (@response, @document_list) = HykuAddons::SimpleWorksCache.new(params[:tenant_id]).fetch query: params.permit!.to_h do
            search_results(params)
          end

          raise Blacklight::Exceptions::RecordNotFound if @response['response']['numFound'].zero?
          @results = @document_list
          @result_count = @response['response']['numFound']
          @facet_counts = @response.aggregations.transform_values { |v| Hash[v.items.pluck(:value, :hits)] }
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "No record found for query_term: #{params[:q]} and filters containing #{params[:f]}" }
        end

        def facet
          if params[:id] == 'all'
            # Set facet.limit to -1 for all facets when sending solr request so all facet values get returned
            solr_params = search_builder.with(params).to_h
            solr_params.each_key { |k| solr_params[k] = -1 if k.match?(/^f\..+\.limit$/) }
            @response = repository.search(solr_params)
            render json: @response.aggregations.transform_values { |v| Hash[v.items.pluck(:value, :hits)] }
          else
            super
            render json: Hash[@display_facet.items[facet_range].pluck(:value, :hits)]
          end
        end

        private

          def facet_offset
            params[:page].present? && params[:per_page].present? ? ([params[:page].to_i, 1].max - 1) * params[:per_page].to_i : 0
          end

          def facet_limit
            params[:per_page].present? ? params[:per_page].to_i : 0
          end

          def facet_range
            facet_offset..(facet_offset + facet_limit - 1)
          end
      end
    end
  end
end
