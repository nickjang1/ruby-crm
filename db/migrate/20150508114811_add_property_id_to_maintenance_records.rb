class AddPropertyIdToMaintenanceRecords < ActiveRecord::Migration
  def change
    add_column :maintenance_records, :property_id, :integer
  end
end
