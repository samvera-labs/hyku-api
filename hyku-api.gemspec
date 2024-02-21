# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "hyku/api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "hyku-api"
  spec.version     = Hyku::API::VERSION
  spec.authors     = ["Chris Colvard"]
  spec.email       = ["tech@ubiquitypress.com", "chris.colvard@gmail.com"]
  spec.homepage    = ""
  spec.summary     = "Limited API for Hyku backend"
  spec.description = "Hyku::API defines a limited API abstracted from Hyku's controller endpoints to be used in the building of custom front ends."
  spec.license     = "Apache-2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0"
  spec.add_dependency 'jwt'

  spec.add_development_dependency "bixby"
  spec.add_development_dependency "pg"
  spec.add_development_dependency 'rspec-rails'
end
