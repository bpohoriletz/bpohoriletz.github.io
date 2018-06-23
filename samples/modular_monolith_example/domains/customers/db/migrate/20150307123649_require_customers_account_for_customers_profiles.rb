class RequireCustomersAccountForCustomersProfiles < ActiveRecord::Migration[5.1]
  def change
    change_column :customers_profiles, :account_id, :integer, null: false
  end
end
