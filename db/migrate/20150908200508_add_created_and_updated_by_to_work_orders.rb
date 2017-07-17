class AddCreatedAndUpdatedByToWorkOrders < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :created_by, :integer
    add_column :maintenance_work_orders, :updated_by, :integer
  end
end
