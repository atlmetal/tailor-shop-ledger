class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price, null: false
      t.integer :material_cost, null: false
      t.boolean :active, null: false, default: true

      t.timestamps

      t.check_constraint "price >= 0 AND material_cost >= 0", name: "services_money_check"
      # One active service per name in a shop, ignoring case; deactivated ones may repeat it.
      t.index "shop_id, lower(name)", unique: true, where: "active", name: "index_services_on_shop_id_and_lower_name"
    end
  end
end
