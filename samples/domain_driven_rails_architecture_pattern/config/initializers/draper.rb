# frozen_string_literal: true

DraperBaseController = Class.new( ActionController::Base )
DraperBaseController.include( ApplicationController )

Draper.configure do |config|
  config.default_controller = DraperBaseController
end
