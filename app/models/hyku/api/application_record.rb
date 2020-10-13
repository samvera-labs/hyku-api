# frozen_string_literal: true
module Hyku
  module Api
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
