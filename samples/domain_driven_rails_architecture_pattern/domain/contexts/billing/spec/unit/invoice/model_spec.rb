# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customers::Account::Model, type: :model do
  context '#save!' do
    it 'saves valid record' do
      expect { build( :customers_account ).save! }.to_not raise_error
    end
  end
end
