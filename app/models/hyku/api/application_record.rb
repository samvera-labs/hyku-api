# frozen_string_literal: true
module Hyku
  module API
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
