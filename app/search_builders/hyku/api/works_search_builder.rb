# frozen_string_literal: true
module Hyku
  module API
    class WorksSearchBuilder < Hyrax::WorksSearchBuilder
      self.default_processor_chain += [:only_active_works, :filter_by_type, :filter_by_metadata] # , :filter_by_availability]

      def filter_by_type(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << "has_model_ssim:#{blacklight_params[:type].camelize.safe_constantize}" if blacklight_params[:type].present?
      end

      def filter_by_metadata(solr_parameters)
        solr_parameters[:q] ||= []
        metadata_params = blacklight_params.except(:availability, :per_page, :page, :format, :controller, :action, :tenant_id).permit!
        metadata_field, metadata_value = metadata_params.to_h.first
        solr_parameters[:q] << "#{map_search_keys[metadata_field.to_sym]}:#{metadata_value}" if metadata_value.present? && map_search_keys[metadata_field.to_sym].present?
      end

      # UP-work type specific
      # def filter_by_availability(solr_parameters)
      #   solr_parameters[:fq] ||= []
      #   solr_parameters[:fq] << "{!term f=file_availability_sim}#{map_search_values[blacklight_params[:availability].to_sym]}" if blacklight_params[:availability].present?
      # end

      private

        # Also move this into the search builder
        def map_search_keys
          {
            creator: 'creator_tesim',
            keyword: 'keyword_sim',
            collection_uuid: 'member_of_collection_ids_ssim',
            language: 'language_sim',
            # availability: 'file_availability_sim'
          }
        end

      # # Below is UP-specific so needs to be in hyku_addons in the search builder?
      # def map_search_values
      #   {
      #     not_available: 'File not available',
      #     available: 'File available from this repository',
      #     external_link:  'External link (access may be restricted)'
      #   }
      # end
    end
  end
end
