class AddCompletedByToMaintenanceRecords < ActiveRecord::Migration
  def change
    add_column :maintenance_records, :completed_by, :integer
  end
end
