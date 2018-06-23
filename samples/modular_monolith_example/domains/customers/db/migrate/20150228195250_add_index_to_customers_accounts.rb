class AddIndexToCustomersAccounts < ActiveRecord::Migration[5.1]
  def change
    add_index :customers_accounts, :email, unique: true
  end
end
