class AddLocaleToCustomersAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :customers_accounts, :locale, :string
  end
end
