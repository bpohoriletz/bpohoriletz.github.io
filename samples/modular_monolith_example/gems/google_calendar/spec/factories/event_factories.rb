require 'factory_bot'

FactoryBot.define do
  factory :recurrent_event, class: GoogleCalendar::Event do
    skip_create

    sequence(:id) { |n| n }
    start { OpenStruct.new( { 'date_time' => ( Time.now - ( 60 * 60 * 24 * 30 ) ).to_s , 'date' => ( Time.now + ( 60 * 60 * 24 * 30 ) ).to_s } ) }
    add_attribute(:end) { OpenStruct.new( { 'date_time' => ( Time.now - ( 60 * 60 * 24 * 30 ) ).to_s, 'date' => ( Time.now + ( 60 * 60 * 24 * 30 ) ).to_s } ) }
    recurrence ["DTSTART;TZID=US-Eastern:19970902T090000\nRRULE:FREQ=DAILY;INTERVAL=2"]
    summary 'Short summary for the event'
  end

  factory :event, class: GoogleCalendar::Event do
    skip_create

    sequence(:id) { |n| n }
    start { OpenStruct.new( { 'date_time' => ( Time.now - ( 60 * 60 * 5 ) ).to_s , 'date' => ( Time.now + ( 60 * 60 * 5 ) ).to_s } ) }
    add_attribute(:end) { OpenStruct.new( { 'date_time' => ( Time.now - ( 60 * 60 * 5 ) ).to_s, 'date' => ( Time.now + ( 60 * 60 * 5 ) ).to_s } ) }
    recurrence ''
    summary 'Short summary for the event'
  end
end
