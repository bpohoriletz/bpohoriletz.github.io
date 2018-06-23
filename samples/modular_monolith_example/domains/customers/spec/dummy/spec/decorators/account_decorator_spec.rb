# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe Customers::AccountDecorator do
  context 'self.google_authorization_url' do
    it 'should generate authorization URL' do
      login
      # TOFIX email empty?
      expect( described_class.google_authorization_url ).to match( /test@test.com/ )
    end
  end
end
