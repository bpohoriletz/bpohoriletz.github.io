require 'draper'

Draper.configure do |config|
  config.default_controller = Customers::ApplicationController
end
