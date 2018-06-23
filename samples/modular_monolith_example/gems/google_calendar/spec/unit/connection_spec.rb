require 'spec_helper'

describe GoogleCalendar::Connection do

  context '#email' do
    it 'is meaningful symbol if connection failed' do
      allow_any_instance_of( Signet::OAuth2::Client ).to receive( :fetch_access_token! ).
                                                         and_raise( Faraday::ConnectionFailed, 'Connection failed!' )

      expect( described_class.new( refresh_token: 'token' ).email ).to eq( :google_calendar_connection_failed )
    end

    it 'is meaningful symbol if connection failed' do
      allow_any_instance_of( Signet::OAuth2::Client ).to receive( :fetch_access_token! )

      expect( described_class.new( refresh_token: nil ).email ).to eq( :google_calendar_refresh_token_empty )
    end

    it 'is a primary calendars email' do
      allow_any_instance_of( Signet::OAuth2::Client ).to receive( :fetch_access_token! )
      allow_any_instance_of( Google::Apis::CalendarV3::CalendarService ).to receive( :get_calendar_list ).
                                                                            with( 'primary' ).
                                                                            and_return( spy( id: 'email@test.com' ) )

      expect( described_class.new( refresh_token: 'token' ).email ).to eq( 'email@test.com' )
    end
  end

  context '#calendar' do
    it 'is a primary calendar' do
      allow_any_instance_of( Signet::OAuth2::Client ).to receive( :fetch_access_token! )
      allow_any_instance_of( Google::Apis::CalendarV3::CalendarService ).to receive( :get_calendar_list ).
                                                                            with( 'primary' ).
                                                                            and_return( :calendar )

      expect( described_class.new( refresh_token: 'token' ).calendar ).to eq( :calendar )
    end
  end

  context 'self.exchange_acces_token_for_refresh' do
    it 'exchanges access token from google for a refresh token for offlie access' do
      allow_any_instance_of( Signet::OAuth2::Client ).to receive( :fetch_access_token! ).
                                                         and_return( spy( fetch: :refresh_token ) )

      expect( described_class.exchange_acces_token_for_refresh( access_token: :token ) ).to eq( :refresh_token )
    end
  end

  context 'self.google_authorization_url' do
    it 'returns a meaningfull symbol if no email was passed' do
      expect( described_class.google_authorization_url( email_address: nil ) ).to eq( :google_calendar_email_empty )
    end

    it 'builds a URL to ask for an offline access to calendar' do
      expect( described_class.google_authorization_url( email_address: 'email@test.com' ) ).to eq( "https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt=force&client_id=959164577857-cpiiln1i48p4p66l6b0dgr4cp874kcfl.apps.googleusercontent.com&redirect_uri=http://localhost:3000/oauth/callback&response_type=code&scope=https://www.googleapis.com/auth/calendar&user_id=email@test.com" )
    end
  end

  context '.calendar_events' do
    it 'fetches events for a given calendar' do
      allow_any_instance_of( Signet::OAuth2::Client ).to receive( :fetch_access_token! )
      allow_any_instance_of( Google::Apis::CalendarV3::CalendarService ).to receive( :list_events ).
                                                                            with( 'primary', any_args ).
                                                                            and_return( spy( items: [] ) )
      allow_any_instance_of( described_class ).to receive( :calendar ).
                                                  and_return( spy( time_zone: 'EEST' ) )

      expect(
        described_class.
        new( refresh_token: 'token' ).
        calendar_events( from: Time.now.to_s, to: ( Time.now + ( 60 * 60 * 24 ) ).to_s )
      ).to eq( [] )
    end
  end
end
