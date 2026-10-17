class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # One user per shop.
      t.references :shop, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
