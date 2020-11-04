# frozen_string_literal: true
if @collections.present?
  json.explore_collections do
    json.partial! 'hyku/api/v1/collection/collection.jbuilder', collection: @collections, as: :collection
  end
else
  json.explore_collections nil
end

if @featured_works.present?
  json.featured_works do
    json.partial! 'hyku/api/v1/work/work.jbuilder', collection: @featured_works, as: :work
  end
else
  json.featured_works nil
end

if @recent_documents.present?
  json.recent_works do
    json.partial! 'hyku/api/v1/work/work.jbuilder', collection: @recent_documents, as: :work
  end
else
  json.recent_works nil
end

json.featured_order do
  json.array! @featured_works_list
end
