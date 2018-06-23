require_relative '../rails_helper'

RSpec.describe Customers::Profile, type: :model do
  it { should validate_presence_of( :first_name ) }
  it { should validate_presence_of( :last_name ) }

  it '\'s name should consist of three parts' do
    profile = build( :profile, { first_name: 'first', middle_name: 'second', last_name: 'third', account: build( :account ) } )
    expect( profile.name ).to eq 'first second third'
  end
end

# == Schema Information
#
# Table name: profiles
#
#  id              :integer          not null, primary key
#  first_name      :string           not null
#  middle_name     :string
#  last_name       :string           not null
#  permissin_level :integer
#  account_id      :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  settings        :text
#  google_login    :string
#
# Indexes
#
#  index_profiles_on_account_id    (account_id)
#  index_profiles_on_google_login  (google_login) UNIQUE
#
