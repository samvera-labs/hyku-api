module Hyku
  module API
    module SolrDocumentBehavior
      extend ActiveSupport::Concern

      def load_parent_docs
        query("member_ids_ssim:#{id}", rows: 1000).map { |res| ::SolrDocument.new(res) }
      end

      def query(query, **opts)
        service_class = defined?(Hyrax::SolrService) ? Hyrax::SolrService : ActiveFedora::SolrService
        result = service_class.post(query, **opts)
        result.fetch('response').fetch('docs', [])
      end
    end
  end
end
