class RequireCustomersProfilesName < ActiveRecord::Migration[5.1]
  def change
    change_column :customers_profiles, :first_name, :string, null: false
    change_column :customers_profiles, :last_name, :string, null: false
  end
end
