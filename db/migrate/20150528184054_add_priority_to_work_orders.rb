class AddPriorityToWorkOrders < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :priority, :string, limit: 1, default: "m"
  end
end
