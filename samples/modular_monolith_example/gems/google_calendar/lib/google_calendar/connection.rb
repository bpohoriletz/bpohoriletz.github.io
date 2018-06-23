module GoogleCalendar
  class Connection
    # Google calendar list
    def calendar_events( from:, to: )
      return [] if service.is_a?( Symbol )

      events = service.list_events(
          'primary',
          time_min:    Time.parse( from ).xmlschema,
          time_max:    Time.parse( to ).xmlschema
      ).items

      # TOFIX
      # Time.with_zone( calendar.time_zone ) { Event.init_multiple( events, from, to ) }
      Event.init_multiple( events, from, to )
    end

    def email
      return @service if @service.is_a? Symbol
      @email ||= service.get_calendar_list( 'primary' ).id
    end

    def calendar
      return @service if @service.is_a? Symbol
      @calendar ||= service.get_calendar_list( 'primary' )
    end

    def self.google_authorization_url( email_address: )
      return :google_calendar_email_empty if email_address.nil? || email_address.empty?
      client_secrets = Google::APIClient::ClientSecrets.load( SECRETS_FILE_PATH )
      client = client_secrets.to_authorization
      client.scope = Google::Apis::CalendarV3::AUTH_CALENDAR

      return client.authorization_uri(
        approval_prompt: :force,
        access_type:     :offline,
        user_id:         email_address
      ).to_s
    end

    def self.exchange_acces_token_for_refresh( access_token: )
      client_secrets = Google::APIClient::ClientSecrets.load( SECRETS_FILE_PATH )
      client = client_secrets.to_authorization
      client.code = access_token
      response = client.fetch_access_token!

      return response.fetch( 'refresh_token' )
    end

    private

    def initialize( refresh_token: )
      return @service = :google_calendar_refresh_token_empty if refresh_token.blank?
      client_secrets = Google::APIClient::ClientSecrets.load( SECRETS_FILE_PATH )
      @authorization = client_secrets.to_authorization
      @authorization.grant_type = 'refresh_token'
      @authorization.refresh_token = refresh_token
      @authorization.fetch_access_token!
    rescue Faraday::ConnectionFailed
      # TOFIX raise exception
      @service = :google_calendar_connection_failed
    end

    def service
      return @service if @service.present?

      @service = Google::Apis::CalendarV3::CalendarService.new
      @service.authorization = @authorization

      return @service
    end
  end
end
