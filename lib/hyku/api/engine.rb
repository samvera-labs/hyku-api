# frozen_string_literal: true
module Hyku
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace Hyku::Api
    end
  end
end
