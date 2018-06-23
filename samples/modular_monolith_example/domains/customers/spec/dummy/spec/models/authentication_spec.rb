require_relative '../rails_helper'

RSpec.describe Customers::Authentication, type: :model do
  it 'validates presence of account' do
    expect( described_class.new.valid? ).to be_falsey
  end
end

# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  account_id :integer          not null
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_authentications_on_provider_and_uid  (provider,uid)
#
