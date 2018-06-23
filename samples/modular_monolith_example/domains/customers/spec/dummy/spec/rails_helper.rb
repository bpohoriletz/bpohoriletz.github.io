# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'
require File.expand_path("../../config/environment.rb", __FILE__)
# TOFIX ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../../db/migrate', __FILE__)

require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'spec_helper'
require 'authlogic'
require 'authlogic/test_case'
require 'factory_bot'
require 'shoulda-matchers'
require 'pry'

FactoryBot.factories.clear
FactoryBot.definition_file_paths = %W(spec/factories)
FactoryBot.reload
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include Authlogic::TestCase
  config.include FactoryBot::Syntax::Methods
  config.include Shoulda::Matchers::ActiveModel, type: :model
  config.include Shoulda::Matchers::ActiveRecord, type: :model

  config.filter_rails_from_backtrace!
end
