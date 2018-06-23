
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "google_calendar/version"

Gem::Specification.new do |spec|
  spec.name          = "google_calendar"
  spec.version       = GoogleCalendar::VERSION
  spec.authors       = ["Bohdan Pohorilets"]
  spec.email         = ["bohdan.pohorilets@gmail.com"]

  spec.summary       = %q{ Functionality to connect to a google calendar and fetch events }
  spec.description   = %q{ Functionality to connect to a google calendar and fetch events }
  spec.homepage      = 'http://example.com'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activemodel'
  spec.add_dependency 'google-api-client', '~> 0.11'
  spec.add_dependency 'ice_cube'
  # Development
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'factory_bot'
end
