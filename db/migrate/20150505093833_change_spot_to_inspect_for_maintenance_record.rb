class ChangeSpotToInspectForMaintenanceRecord < ActiveRecord::Migration
  def change
    rename_column :maintenance_records, :spot_check_at, :inspected_on
    rename_column :maintenance_records, :spot_check_by_id, :inspected_by_id
    rename_column :maintenance_records, :spot_check_notes, :inspected_notes
  end
end
