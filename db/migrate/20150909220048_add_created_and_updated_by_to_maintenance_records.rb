class AddCreatedAndUpdatedByToMaintenanceRecords < ActiveRecord::Migration
  def change
    add_column :maintenance_records, :created_by, :integer
    add_column :maintenance_records, :updated_by, :integer
  end
end
