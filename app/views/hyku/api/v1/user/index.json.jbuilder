# frozen_string_literal: true
json.array!(@users) do |_user|
  json.partial! 'user', user: @user
end
