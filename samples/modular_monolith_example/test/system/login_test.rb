require 'application_system_test_case'
require File.join(Rails.root.to_s, 'test', 'support', 'pages', 'accounts', 'login')

class UsersTest < ApplicationSystemTestCase

  def test_login_is_functional
    load "#{Rails.root}/db/seeds.rb"
    ::Pages::Accounts::Login.new(test: self, url: customers.login_url ).instance_eval do
      visit
      # Validate content
      password_present?
      login_present?
      submit_present?
      # Log in
      login.set( Customers::Account.first.email )
      password.set( 'Test1234' )
      submit.click
      assert_text( 'Accounts' )
    end
  ensure
    Customers::Account.all.map(&:destroy!)
  end
end
