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
    end
  end
end
