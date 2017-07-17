class AddAssignedToToWorkOrders < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :assigned_to_id, :integer
  end
end
