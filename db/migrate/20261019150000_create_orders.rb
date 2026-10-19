class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      # A shop's orders are listed by the day they were left: the index below starts with shop_id and serves it.
      t.references :shop, null: false, foreign_key: true, index: false
      t.string :customer_name, null: false
      t.date :received_on, null: false

      t.timestamps

      t.index %i[ shop_id received_on ]
    end
  end
end
