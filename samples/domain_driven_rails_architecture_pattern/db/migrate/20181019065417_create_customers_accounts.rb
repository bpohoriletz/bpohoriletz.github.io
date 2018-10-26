# frozen_string_literal: true

# :nodoc:
class CreateCustomersAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :customers_accounts, &:timestamps
  end
end
