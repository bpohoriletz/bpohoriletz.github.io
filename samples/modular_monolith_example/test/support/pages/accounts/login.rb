require_relative '../base'

module Pages
  module Accounts
    class Login < Pages::Base
      has_node :login, '#account_session_email'
      has_node :password, '#account_session_password'
      has_node :submit, '#account_credentials_submit'
    end
  end
end
