# frozen_string_literal: true
json.total @user_count
json.items do
  json.array! @users.each do |user|
    json.partial! 'user', user: user
  end
end
