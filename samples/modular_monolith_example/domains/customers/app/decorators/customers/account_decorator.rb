module Customers
  class AccountDecorator < Draper::Decorator
    delegate_all

    def self.google_authorization_url( account: WebSession.find.account )
      # TOFIX profile.google_login
      GoogleCalendar::Connection.google_authorization_url( email_address: account.email )
    end
  end
end
