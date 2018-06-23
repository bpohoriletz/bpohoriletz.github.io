require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'

require 'google_calendar/version'
require 'google_calendar/connection'
require 'google_calendar/event'

module GoogleCalendar
  SECRETS_FILE_PATH = "#{__dir__}/../client_secrets.json".freeze
end
