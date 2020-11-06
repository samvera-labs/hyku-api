# frozen_string_literal: true
json.total @work_count
json.items do
  json.partial! 'work', collection: @works, as: :work
end
