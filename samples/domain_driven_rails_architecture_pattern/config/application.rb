# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require "action_cable/engine"
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DomainDrivenRailsArchitecturePattern
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    paths[ 'app/assets' ]         = 'representations/assets'
    paths[ 'app/views' ]          = 'representations/views'
    paths[ 'config/routes.rb' ]   = 'representations/routes.rb'
    paths[ 'config/database' ]    = 'domain/database.yml'
    paths[ 'public' ]             = 'representations/public'
    paths[ 'public/javascripts' ] = 'representations/public/javascripts'
    paths[ 'public/stylesheets' ] = 'representations/public/stylesheets'
    paths[ 'vendor' ]             = 'representations/vendor'
    paths[ 'vendor/assets' ]      = 'representations/vendor/assets'
    # impacts where Rials will look for an ApplicationController and ApplicationRecord
    paths[ 'app/controllers' ] = 'representations/controllers'
    paths[ 'app/models' ]      = 'domain/contexts'

    %W[
      #{ File.expand_path( '../representations/concerns', __dir__ ) }
      #{ File.expand_path( '../representations/controllers', __dir__ ) }
      #{ File.expand_path( '../domain/concerns', __dir__ ) }
      #{ File.expand_path( '../domain/contexts', __dir__ ) }
    ].each do |path|
      config.autoload_paths   << path
      config.eager_load_paths << path
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
