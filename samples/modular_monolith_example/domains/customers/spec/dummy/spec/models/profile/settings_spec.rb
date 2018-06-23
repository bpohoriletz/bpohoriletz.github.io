require_relative '../../rails_helper'

RSpec.describe Customers::Profile, type: :model do
  it 'should add corresponding method to profile for methods from SETTINGS' do
    profile = described_class.new
    described_class::SETTINGS.each do |method|
      expect( profile.respond_to?( method ) ).to eq true
      expect( profile.public_send( method ) ).to eq nil # since values are empty
      expect( profile.public_send( method + '=', true ) ).to eq true
    end
  end

  it 'should not add any extra methods' do
    profile = described_class.new
    expect( profile.respond_to?( :unknown_method ) ).to eq false
    expect{ profile.unknown_method }.to raise_error NoMethodError
  end
end
