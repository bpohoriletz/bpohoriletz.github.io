# frozen_string_literal: true

require 'action_controller/railtie'
require 'active_support'
require 'rspec/rails'
require 'spec_helper'

RepresentationsTestApplication = Class.new( ::Rails::Application )
::Rails.application = RepresentationsTestApplication.new
require_relative '../routes'

require 'pry-byebug'
require 'uuid'

%w[ concerns controllers decorators ].each do |folder|
  Dir[ File.expand_path( "../#{folder}/**/*.rb", __dir__ ) ].each { |f| require f }
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.define_derived_metadata( file_path: Regexp.new( './controllers/' ) ) do |metadata|
    metadata[ :type ] = :controller
  end
  config.define_derived_metadata( file_path: Regexp.new( './views/' ) ) do |metadata|
    metadata[ :type ] = :view
  end

  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
