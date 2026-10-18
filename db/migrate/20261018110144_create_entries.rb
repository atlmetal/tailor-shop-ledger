class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      # A shop's entries are looked up by day: the index below starts with shop_id and serves it.
      t.references :shop, null: false, foreign_key: true, index: false
      t.string :kind, null: false
      t.date :occurred_on, null: false
      t.string :concept, null: false
      t.integer :amount, null: false

      t.timestamps

      t.index %i[ shop_id occurred_on ]
      t.check_constraint "kind IN ('expense', 'income')", name: "entries_kind_check"
      t.check_constraint "amount > 0", name: "entries_amount_check"
    end
  end
end
