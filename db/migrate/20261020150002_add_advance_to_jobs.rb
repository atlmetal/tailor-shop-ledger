class AddAdvanceToJobs < ActiveRecord::Migration[8.1]
  def change
    add_reference :jobs, :advance, foreign_key: true
    add_check_constraint :jobs, "order_id IS NULL OR advance_id IS NULL", name: "jobs_order_or_advance_check"
  end
end
