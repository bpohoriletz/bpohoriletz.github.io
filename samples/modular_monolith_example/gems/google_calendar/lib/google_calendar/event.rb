require 'active_model'
require 'ice_cube'

module GoogleCalendar
  class Event
    include ActiveModel::Model
    attr_accessor :id, :start, :end, :summary, :recurrence

    def self.init_multiple( events, from, to )
      events.map{ |event| event.recurrence.present? ? recurrent_to_multiple( event, from, to ) : initialize_from_google( event ) }.flatten.compact
    end

    # TOFIX
    # dummy method to look like usual event
    def document_row_id
      0
    end

    # TOFIX
    # dummy method to look like usual event
    def profile_id
      0
    end

    def self.recurrent_to_multiple( event, from, to )
      event_start = Time.parse ( event.start.date_time || event.start.date ).to_s
      event_end   = Time.parse ( event.end.date_time || event.end.date ).to_s
      schedule    = IceCube::Schedule.from_ical( event.recurrence[ 0 ] )
      duration    = event_end - event_start

      schedule.start_time = event_start
      schedule.occurrences_between( Time.parse( from ), Time.parse( to ) ).map do |date|
        new(
          id:      "#{event.id}_#{date.start_time}",
          start:   date.start_time,
          end:     date.start_time + duration,
          summary: event.summary
        )
      end
    end

    def self.initialize_from_google( event )
      event_start = Time.parse ( event.start.date_time || event.start.date ).to_s
      event_end   = Time.parse ( event.end.date_time || event.end.date ).to_s
      new(
        id:      event.id,
        start:   event_start,
        end:     event_end,
        summary: event.summary
      )
    end

    def attributes
      {
        'id' => id,
        'start' => start,
        'end' => public_send( :end ),
        'summary' => summary,
        'recurrence' => recurrence
      }
    end

    def [](key)
      attributes[ key ]
    end
  end
end
