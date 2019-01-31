# frozen_string_literal: true

require 'active_record/railtie'
require 'active_support'
require 'rspec/rails'

ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require 'database_cleaner'
require 'factory_bot'
require 'pry-byebug'

ContextsTestApplication = Class.new( ::Rails::Application )
::Rails.application = ContextsTestApplication.new

database_configurations = YAML.load(
  ERB.new(
    File.read( File.expand_path( '../database.yml', __dir__ ) )
  ).result
)

ActiveRecord::Base.establish_connection( database_configurations[ 'test' ] )

%w[ concerns contexts ].each do |folder|
  Dir[ File.expand_path( "../#{folder}/**/*.rb", __dir__ ) ].each { |f| require f }
end

Dir[ './spec/support/*.rb' ].each { |f| require f }

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
