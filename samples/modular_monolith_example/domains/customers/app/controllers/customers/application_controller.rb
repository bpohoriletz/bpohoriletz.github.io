module Customers
  class ApplicationController < ActionController::Base
    include Authorization
    protect_from_forgery with: :exception

    before_action :require_account
    before_action :set_locale
  end
end
