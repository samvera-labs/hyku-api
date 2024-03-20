# frozen_string_literal: true
# FIXME: many attributes here left nil so specs will pass
json.cache! [@account, :works, work.id, work.solr_document[:_version_],
             work.solr_document[:member_of_collection_ids] & collection_docs.pluck('id')] do
  json.uuid work.id

  json.abstract work.description.first
  #                                         "additional_info" => nil,
  #                                         "additional_links" => nil,
  json.admin_set_name work.admin_set.first
  #                                         "alternative_journal_title" => nil,
  #                                         "alternative_title" => nil,
  #                                         "article_number" => nil,
  #                                         "book_title" => nil,
  #                                         "buy_book" => nil,
  #                                         "challenged" => nil,
  json.cname @account.cname
  #                                         "collections" => nil,
  json.contributor work.contributor
  json.creator work.creator
  #                                         "current_he_institution" => nil,
  #                                         "date_accepted" => nil,
  #                                         "date_published" => nil,
  json.date_submitted work.date_uploaded
  #                                         "degree" => nil,
  #                                         "dewey" => nil,
  #                                         "display" => "full",
  #                                         "doi" => nil,
  # json.download_link nil
  #                                         "duration" => nil,
  #                                         "edition" => nil,
  #                                         "eissn" => nil,
  #                                         "event_date" => nil,
  #                                         "event_location" => nil,
  #                                         "event_title" => nil,
  # TODO: Put it back on
  #json.files do
  # json.has_private_files work.file_set_presenters.any? { |fsp| fsp.solr_document.private? }
  # json.has_registered_files work.file_set_presenters.any? { |fsp| fsp.solr_document.registered? }
  # json.has_public_files work.file_set_presenters.any? { |fsp| fsp.solr_document.public? }
  #end
  #                                         "funder" => nil,
  #                                         "funder_project_reference" => nil,
  #                                         "institution" => nil,
  #                                         "irb_number" => nil,
  #                                         "irb_status" => nil,
  #                                         "is_included_in" => nil,
  #                                         "isbn" => nil,
  #                                         "issn" => nil,
  #                                         "issue" => nil,
  #                                         "journal_title" => nil,
  json.keywords work.keyword
  json.language work.language
  #                                         "library_of_congress_classification" => nil,
  json.license nil
  #                                         "location" => nil,
  #                                         "material_media" => nil,
  #                                         "migration_id" => nil,
  #                                         "official_url" => nil,
  #                                         "organisational_unit" => nil,
  #                                         "outcome" => nil,
  #                                         "page_display_order_number" => nil,
  #                                         "pagination" => nil,
  #                                         "participant" => nil,
  #                                         "photo_caption" => nil,
  #                                         "photo_description" => nil,
  #                                         "place_of_publication" => nil,
  #                                         "project_name" => nil,
  json.publisher work.publisher
  #                                         "qualification_level" => nil,
  #                                         "qualification_name" => nil,
  #                                         "reading_level" => nil,
  #                                         "related_exhibition" => nil,
  #                                         "related_exhibition_date" => nil,
  #                                         "related_exhibition_venue" => nil,
  json.related_url work.related_url
  json.resource_type work.resource_type
  #                                         "review_data" => nil,
  #                                         "rights_holder" => nil,
  json.rights_statement work.rights_statement
  #                                         "series_name" => nil,
  json.source work.source
  json.subject work.subject
  # TODO: Put it back on
  # if work.representative_presenter&.solr_document&.public?
  #   json.representative_id work.representative_id
  # else
  #   json.representative_id nil
  # end
  # json.thumbnail_base64_string nil
  if work.thumbnail_presenter&.solr_document&.public?
    components = {
      scheme: Rails.application.routes.default_url_options.fetch(:protocol, 'http'),
      host: @account.cname,
      path: work.solr_document.thumbnail_path.split('?')[0],
      query: work.solr_document.thumbnail_path.split('?')[1]
    }
    json.thumbnail_url URI::Generic.build(components).to_s
  else
    json.thumbnail_url nil
  end
  json.title work.title.first
  json.type "work"
  #                                         "version" => nil,
  json.visibility work.solr_document.visibility
  #                                         "volume" => nil,
  json.work_type work.model.model_name.to_s
  json.workflow_status work.solr_document.workflow_state

  collection_presenters = work.member_of_collection_presenters.reject { |coll| coll.is_a? Hyrax::AdminSetPresenter }
  collections = collection_presenters.map { |collection| { uuid: collection.id, title: collection.title.first } }
  json.collections collections

  json.total_items @total_items
  json.items @items
end
