class CreateAdvances < ActiveRecord::Migration[8.1]
  def change
    create_table :advances do |t|
      # The index below starts with shop_id and serves the shop's advances.
      t.references :shop, null: false, foreign_key: true, index: false
      t.string :customer_name, null: false

      t.timestamps

      # One advance per customer in a shop, ignoring case.
      t.index "shop_id, lower(customer_name)", unique: true, name: "index_advances_on_shop_id_and_lower_customer_name"
    end
  end
end
