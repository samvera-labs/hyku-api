# frozen_string_literal: true
Hyku::API::Engine.routes.draw do
  scope 'api' do
    namespace :v1 do
      resources :tenant, only: [:index, :show], defaults: { format: :json } do
        resources :work, only: [:index, :show], defaults: { format: :json } do
          member do
            get 'manifest'
            get 'files', to: 'files#index'
            post 'featured_works', to: 'featured_works#create'
            delete 'featured_works', to: 'featured_works#destroy'
            post 'reviews', to: 'reviews#create'
          end
        end
        resources :collection, only: [:index, :show], defaults: { format: :json }
        get 'search', to: 'search#index'
        get 'search/facet/:id', to: 'search#facet'
        get 'highlights', to: 'highlights#index'
        post 'contact_form', to: 'contact_form#create'
        # user routes
        post 'users/login', to: 'sessions#create'
        get 'users/log_out', to: 'sessions#destroy'
        post 'users/refresh', to: 'sessions#refresh'
        post 'users/signup', to: 'registrations#create'
      end
      get 'errors', to: 'errors#index', defaults: { format: :json }
    end
  end
end
