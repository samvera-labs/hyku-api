Rails.application.routes.draw do
  mount Hyku::Api::Engine => "/hyku-api"
end
