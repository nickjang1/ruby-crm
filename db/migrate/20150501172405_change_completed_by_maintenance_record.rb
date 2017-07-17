class ChangeCompletedByMaintenanceRecord < ActiveRecord::Migration
  def change
    rename_column :maintenance_records, :completed_by, :completed_by_id
  end
end
