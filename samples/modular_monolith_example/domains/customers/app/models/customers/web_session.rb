module Customers
  class WebSession < ::Authlogic::Session::Base
    # configuration here, see documentation for sub modules of Authlogic::Session
    logout_on_timeout true
    authenticate_with Customers::Account
  end
end
