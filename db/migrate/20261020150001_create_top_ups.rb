class CreateTopUps < ActiveRecord::Migration[8.1]
  def change
    create_table :top_ups do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :advance, null: false, foreign_key: true
      t.date :paid_on, null: false
      t.integer :amount, null: false

      t.timestamps

      t.check_constraint "amount > 0", name: "top_ups_amount_check"
    end
  end
end
