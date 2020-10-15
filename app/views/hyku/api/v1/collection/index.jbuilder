# frozen_string_literal: true
json.total @collection_count
json.items do
  json.partial! 'collection', collection: @collections, as: :collection
end
