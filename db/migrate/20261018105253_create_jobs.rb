class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      # A shop's jobs are looked up by day: the index below starts with shop_id and serves it.
      t.references :shop, null: false, foreign_key: true, index: false
      t.references :service, null: false, foreign_key: true
      t.date :done_on, null: false
      t.integer :quantity, null: false
      t.integer :price, null: false
      t.integer :material_cost, null: false

      t.timestamps

      t.index %i[ shop_id done_on ]
      t.check_constraint "quantity >= 1 AND price >= 0 AND material_cost >= 0", name: "jobs_amounts_check"
    end
  end
end
