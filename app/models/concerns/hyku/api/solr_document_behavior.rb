module Hyku
  module API
    module SolrDocumentBehavior
      extend ActiveSupport::Concern

      def load_parent_docs
        query("member_ids_ssim:#{id}", rows: 1000)
          .map { |res| ::SolrDocument.new(res) }
      end

    end
  end
end
