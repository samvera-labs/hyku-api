module Hyku
  module API
    module SolrDocumentBehavior
      extend ActiveSupport::Concern

      def load_parent_docs
        query("member_ids_ssim:#{id}", rows: 1000).map { |res| ::SolrDocument.new(res) }
      end

      def query(query, **opts)
        result = Hyrax::SolrService.post(query, **opts)
        result.fetch('response').fetch('docs', [])
      end
    end
  end
end
