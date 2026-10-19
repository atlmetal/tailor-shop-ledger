class AddOrderToJobs < ActiveRecord::Migration[8.1]
  def change
    add_reference :jobs, :order, foreign_key: true
  end
end
