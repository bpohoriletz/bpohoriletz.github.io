require 'spec_helper'

RSpec.describe GoogleCalendar::Event do
   let(:event) { FactoryBot.build(:event) }

   it 'should never have a document and profile' do
     expect( event.profile_id ).to eq 0
     expect( event.document_row_id ).to eq 0
   end

   context 'self.recurrent_to_multiple' do
     it 'converts recurrent event to multiple instances if the class' do
       events = described_class.recurrent_to_multiple( FactoryBot.build(:recurrent_event),
                                                       ( Time.now - ( 60 * 60 * 24 * 2 ) ).to_s,
                                                       ( Time.now + ( 60 * 60 * 24 * 2 ) ).to_s)
       expect(events).to_not be_empty
     end
   end

   context 'self.init_multiple' do
     it 'converts recurrent and simple events to an array of simple events' do
       events = described_class.init_multiple(
         [ FactoryBot.build(:recurrent_event), FactoryBot.build(:event) ],
         ( Time.now - ( 60 * 60 * 24 * 2 ) ).to_s,
         ( Time.now + ( 60 * 60 * 24 * 2 ) ).to_s
       )

       expect(events).to_not be_empty
     end
   end

   context '#[]' do
     it 'fetches proper attributes if a key is passed' do
       expect( event[ 'end' ] ).to eq( event.end )
     end
   end
end

# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_authentications_on_provider_and_uid  (provider,uid)
#
