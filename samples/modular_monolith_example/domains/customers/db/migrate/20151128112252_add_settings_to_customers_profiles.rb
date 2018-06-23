class AddSettingsToCustomersProfiles < ActiveRecord::Migration[5.1]
  def change
    add_column :customers_profiles, :settings, :text
    remove_column :customers_profiles, :google_login, :string
    remove_column :customers_accounts, :locale, :string
  end
end
