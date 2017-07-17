class AddDeletedAtToEquipment < ActiveRecord::Migration
  def change
    remove_column :maintenance_equipment, :removed, :boolean
    add_column :maintenance_equipment, :deleted_at, :datetime
    add_column :maintenance_equipment_types, :deleted_at, :datetime
  end
end
