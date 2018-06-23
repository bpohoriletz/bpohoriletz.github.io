ACCOUNT_INTERFACE = { profile_id: -1,
                      name: 'Account',
                      email: 'test@test.com',
                      authentications: [],
                      'present?' => true,
                      'admin?' => false,
                      google_calendar_events: [],
                      locale: :en }.freeze

def login
  # TOFIX JURIST::SESSION
  allow( Customers::WebSession ).to receive_message_chain( :find, :account ).
                         and_return( double( ACCOUNT_INTERFACE ) )
end

def login_as_administrator
  # TOFIX JURIST::SESSION
  allow( Customers::WebSession ).to receive_message_chain( :find, :account ).
                         and_return( double( ACCOUNT_INTERFACE.merge( 'admin?' => true ) ) )
end

def current_account
  Customers::WebSession.find
end
