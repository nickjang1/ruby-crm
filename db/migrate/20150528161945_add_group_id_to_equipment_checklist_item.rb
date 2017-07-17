class AddGroupIdToEquipmentChecklistItem < ActiveRecord::Migration
  def change
    add_column :maintenance_equipment_checklist_items, :user_id, :integer
    add_column :maintenance_equipment_checklist_items, :property_id, :integer
    add_column :maintenance_equipment_checklist_items, :group_id, :integer
  end
end
