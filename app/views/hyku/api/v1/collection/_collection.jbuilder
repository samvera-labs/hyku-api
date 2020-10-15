# frozen_string_literal: true
# FIXME: many attributes here left nil so specs will pass
json.uuid collection.id
json.cname @account.cname
json.date_created collection.date_created&.first
json.date_published nil
json.description collection.description&.first
json.keywords collection.keyword&.first
json.language collection.language&.first
json.license_for_api_tesim collection.license&.first
json.publisher collection.publisher&.first
json.related_url collection.related_url&.first
json.resource_type collection.resource_type&.first
json.rights_statements_for_api_tesim collection.rights_statement&.first
json.thumbnail_base64_string nil
json.thumbnail_url collection.thumbnail_path
json.title collection.title&.first
json.type "collection"
json.visibility collection.visibility
json.volumes nil
# FIXME: gather works and display them for show (not index)
json.works []
