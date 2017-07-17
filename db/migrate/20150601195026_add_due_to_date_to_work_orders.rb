class AddDueToDateToWorkOrders < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :due_to_date, :datetime
  end
end
