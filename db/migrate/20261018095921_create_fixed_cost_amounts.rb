class CreateFixedCostAmounts < ActiveRecord::Migration[8.1]
  def change
    create_table :fixed_cost_amounts do |t|
      t.references :shop, null: false, foreign_key: true
      # The unique index below, which starts with fixed_cost_id, serves its lookups.
      t.references :fixed_cost, null: false, foreign_key: true, index: false
      t.date :starts_on, null: false
      t.integer :amount, null: false

      t.timestamps

      t.index %i[ fixed_cost_id starts_on ], unique: true
      t.check_constraint "amount >= 0", name: "fixed_cost_amounts_amount_check"
      t.check_constraint "EXTRACT(DAY FROM starts_on) = 1", name: "fixed_cost_amounts_starts_on_check"
    end
  end
end
