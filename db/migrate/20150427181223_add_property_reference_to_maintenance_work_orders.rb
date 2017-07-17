class AddPropertyReferenceToMaintenanceWorkOrders < ActiveRecord::Migration
  def change
    add_reference :maintenance_work_orders, :property, index: true
  end
end
