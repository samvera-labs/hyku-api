# frozen_string_literal: true
module Hyku
  module API
    module V1
      class SearchController < BaseController
        include Hyku::API::V1::SearchBehavior

        include Blacklight::Configurable
        copy_blacklight_config_from(::CatalogController)

        def index
          super
          raise Blacklight::Exceptions::RecordNotFound if @response['response']['numFound'].zero?

          collection_search_builder = Hyrax::CollectionSearchBuilder.new(self).with_access(:read).rows(1_000_000)
          @collection_docs = repository.search(collection_search_builder).documents

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
            render json: @response.aggregations.transform_values { |v| hash_of_terms_ordered_by_hits(v.items) }
          else
            super
            render json: hash_of_terms_ordered_by_hits(@display_facet.items[facet_range])
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

          def hash_of_terms_ordered_by_hits(items)
            Hash[items.pluck(:value, :hits).sort_by(&:second).reverse]
          end
      end
    end
  end
end
