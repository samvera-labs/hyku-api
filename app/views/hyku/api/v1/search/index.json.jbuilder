# frozen_string_literal: true
json.total @result_count

json.items do
  json.array! @results do |result|
    if result.collection?
      json.partial! 'hyku/api/v1/collection/collection', locals: { collection: Hyrax::CollectionPresenter.new(result, current_ability, request) }
    else
      json.partial! 'hyku/api/v1/work/work', work: Hyku::WorkShowPresenter.new(result, current_ability, request)
    end
  end
end

json.facet_counts do
  @facets.each do |key, value|
    # converts {resource_type_sim:  ["Dataset default Dataset", 4, "Book default Book", 2, "GenericWork Patent", 1, "TimeBasedMedia Audio", 1]}
    # into this form
    # {Just  using resource_type facet as an example of how each should return data}
    data = { key => Hash[*value] }
    json.merge! data
  end
end
