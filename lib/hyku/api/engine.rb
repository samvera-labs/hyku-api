# frozen_string_literal: true
module Hyku
  module API
    class Engine < ::Rails::Engine
      isolate_namespace Hyku::API

      # Automount this engine
      # Only do this because this is just for us and we don't need to allow control over the mount to the application
      initializer 'hyku_api.routes' do |app|
        app.routes.append do
          mount Hyku::API::Engine, at: '/', as: :hyku_api
        end
      end

      def self.dynamically_include_mixins
        Hyrax::WorkShowPresenter.include Hyku::API::WorkShowPresenterBehavior
        Hyku::SolrDocument.include Hyku::API::SolrDocumentBehavior
      end

      if Rails.env.development?
        config.to_prepare { Hyku::API::Engine.dynamically_include_mixins }
      else
        config.after_initialize { Hyku::API::Engine.dynamically_include_mixins }
      end
    end
  end
end
