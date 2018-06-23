$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "customers/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "customers"
  s.version     = Customers::VERSION
  s.authors     = ["Bohdan Pohorilets"]
  s.email       = ["bohdan.pohorilets@gmail.com"]
  s.homepage    = "http://example.com"
  s.summary     = "Customers management"
  s.description = "Customers management"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency 'authlogic'
  s.add_dependency 'best_in_place', '~> 3.0.1'
  s.add_dependency 'draper'
  s.add_dependency 'google_calendar'
  s.add_dependency 'haml'
  s.add_dependency 'rails'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'sqlite3'
end
