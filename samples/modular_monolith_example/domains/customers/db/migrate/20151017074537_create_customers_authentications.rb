class CreateCustomersAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :customers_authentications do |t|
      t.integer :account_id, null: false
      t.string :provider, :uid, null: false

      t.timestamps
    end

    add_index :customers_authentications, [ :provider, :uid ]
  end
end
