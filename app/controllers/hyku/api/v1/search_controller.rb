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
          super
          raise Blacklight::Exceptions::RecordNotFound if @response['response']['numFound'].zero?
          @results = @document_list
          @result_count = @response['response']['numFound']
          @facets = @response['facet_counts']['facet_fields']
        rescue Blacklight::Exceptions::RecordNotFound
          render json: { status: 404, code: 'not_found', message: "No record found for query_term: #{params[:q]} and filters containing #{params[:f]}" }
        end

        def facet
          if params[:id] == 'all'
            (@response,) = search_results(params)
            render json: @response['facet_counts']['facet_fields'].transform_values { |v| Hash[*v] }
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
