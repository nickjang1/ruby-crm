class AddEquipmentChecklistGroupIdToMaintenanceRecords < ActiveRecord::Migration
  def change
    add_column :maintenance_records, :equipment_checklist_group_id, :integer
  end
end
