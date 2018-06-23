require_relative '../rails_helper'

RSpec.describe Customers::Account, type: :model do
  let( :account ) { build( :account, profile: build( :profile ) ) }

  # TOFIX
  #subject { create( :account ) }
  #it { should validate_presence_of( :email ) }
  #it { should validate_uniqueness_of( :email ).case_insensitive }

  context '#safe_destroy' do

    it 'will not delete an admin' do
      flash = spy( ActionDispatch::Flash )
      allow( account ).to receive( :admin? ).
                       and_return( true )
      account.safe_destroy( flash )

      expect(flash).to have_received( :[]= ).
                       with( :error, "activerecord.models.account.messages.delete_admin" )
    end

    it 'will delete non admins' do
      flash = spy( ActionDispatch::Flash )
      allow( account ).to receive( :admin? ).
                       and_return( false )
      account.safe_destroy( flash )

      expect(flash).to have_received( :[]= ).
                       with( :notice, [ "activerecord.models.account.messages.deleted", { name: "test  test" } ] )
    end
  end

  context 'without linked google calendar' do
    it '#google_calendar is empty' do
      expect( account.google_calendar ).to eq( :google_calendar_refresh_token_empty )
    end
  end

  context 'with linked google calendar' do
    it 'may be authenticated against google API' do
      #account.profile.google_login = account.email
      # TOFIX account.save!
      #allow_any_instance_of( described_class ).to receive( :google_client ).
                                                  #and_return( spy( email: account.email ) )

      #expect( described_class.build_google_authentication( refresh_token: 'access_token' ).valid? ).to be_truthy
    end

    it 'calendar is not empty' do
      allow_any_instance_of( described_class ).to receive( :google_client ).
                                               and_return( spy( calendar: spy( id: account.email ) ) )

      expect( account.google_calendar.id ).to eq( account.email )
    end

    it 'loads events from calendar' do
      allow_any_instance_of( described_class ).to receive( :google_client ).
                                               and_return( spy( calendar_events: [ :one ] ) )

      expect( account.google_calendar_events( from: Time.now.to_s, to: ( Time.now + 4.weeks ).to_s ) ).to eq( [ :one ] )
    end
  end
end

# == Schema Information
#
# Table name: accounts
#
#  id                  :integer          not null, primary key
#  email               :string           not null
#  crypted_password    :string           not null
#  password_salt       :string           not null
#  persistence_token   :string           not null
#  single_access_token :string           not null
#  perishable_token    :string           not null
#  login_count         :integer          default(0), not null
#  failed_login_count  :integer          default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string
#  last_login_ip       :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_accounts_on_email  (email) UNIQUE
#
