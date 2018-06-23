class CreateCustomersProfiles < ActiveRecord::Migration[5.1]
  def change
    create_table :customers_profiles do |t|
      t.string     :first_name
      t.string     :middle_name
      t.string     :last_name
      t.integer    :permissin_level, default: 0, index: true
      t.integer    :account_id,                  index: true

      t.timestamps null: false
    end
    add_foreign_key :customers_profiles, :customers_accounts, column: :account_id
  end
end
