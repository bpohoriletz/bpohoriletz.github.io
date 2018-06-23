class ApplicationController < ActionController::Base
  include Customers::Authorization
end
