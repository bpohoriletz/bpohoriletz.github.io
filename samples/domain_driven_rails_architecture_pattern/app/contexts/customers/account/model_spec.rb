# frozen_string_literal: true

module Customers
  module Account
    # Account database persistence
    class Model < ActiveRecord::Base
      include ::ApplicationRecord
      self.table_name = 'customers_accounts'
    end
  end
end
