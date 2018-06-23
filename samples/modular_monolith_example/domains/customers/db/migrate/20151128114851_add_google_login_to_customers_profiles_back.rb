class AddGoogleLoginToCustomersProfilesBack < ActiveRecord::Migration[5.1]
  def change
    add_column :customers_profiles, :google_login, :string
    add_index  :customers_profiles, :google_login, unique: true
  end
end
