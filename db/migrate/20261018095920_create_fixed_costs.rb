class CreateFixedCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :fixed_costs do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :averaged, null: false, default: false

      t.timestamps
    end
  end
end
