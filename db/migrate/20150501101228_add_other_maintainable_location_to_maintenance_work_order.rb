class AddOtherMaintainableLocationToMaintenanceWorkOrder < ActiveRecord::Migration
  def change
    add_column :maintenance_work_orders, :other_maintainable_location, :string
  end
end
