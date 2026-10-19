class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      # A shop's payments are looked up by day: the index below starts with shop_id and serves it.
      t.references :shop, null: false, foreign_key: true, index: false
      t.references :order, null: false, foreign_key: true
      t.date :paid_on, null: false
      t.integer :amount, null: false

      t.timestamps

      t.index %i[ shop_id paid_on ]
      t.check_constraint "amount > 0", name: "payments_amount_check"
    end
  end
end
