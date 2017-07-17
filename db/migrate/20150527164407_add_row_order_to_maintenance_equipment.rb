class AddRowOrderToMaintenanceEquipment < ActiveRecord::Migration
  def change
    add_column :maintenance_equipment_types, :row_order, :integer
    add_column :maintenance_equipment_checklist_items, :row_order, :integer
  end
end
