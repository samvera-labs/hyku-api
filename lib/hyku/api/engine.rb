module Hyku
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace Hyku::Api
    end
  end
end
