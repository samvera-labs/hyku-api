# frozen_string_literal: true

module Hyku
  module API
    module WorkShowPresenterBehavior
      extend ActiveSupport::Concern
      # @return FileSetPresenter presenter for the thumbnail FileSets
      def thumbnail_presenter
        return nil if thumbnail_id.blank?
        @thumbnail_presenter ||=
          begin
            result = member_presenters_for([thumbnail_id]).first
            return nil if result.try(:id) == id
            if result.respond_to?(:thumbnail_presenter)
              result.thumbnail_presenter
            else
              result
            end
          end
      end

      def parent_works(current_user = nil)
        @parent_works ||= fetch_parent_works(current_user)
      end

      private

      def fetch_parent_works(current_user)
        docs = solr_document.load_parent_docs
        current_user ? accessible_docs_for(docs, current_user) : public_docs(docs)
      end

      def accessible_docs_for(docs, current_user)
        docs.select { |doc| current_user.ability.can?(:read, doc) }
      end

      def public_docs(docs)
        docs.select(&:public?)
      end
    end
  end
end
