class CreateShops < ActiveRecord::Migration[8.1]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.date :started_on, null: false
      # Weekdays as Date#wday numbers, 0 for Sunday: Monday to Saturday by default.
      t.integer :work_days, array: true, null: false, default: [ 1, 2, 3, 4, 5, 6 ]

      t.timestamps

      t.check_constraint "cardinality(work_days) > 0 AND work_days <@ ARRAY[0, 1, 2, 3, 4, 5, 6]", name: "shops_work_days_check"
    end
  end
end
