class CreateMaintenanceEquipmentTypes < ActiveRecord::Migration
  def change
    create_table :maintenance_equipment_types do |t|
      t.string :name
      t.integer :property_id
      t.integer :user_id
      t.text :instruction

      t.timestamps
    end

    create_table :maintenance_equipment_checklist_items do |t|
      t.string :name
      t.text :tools_required
      t.integer :equipment_type_id
      t.integer :frequency

      t.timestamps
    end
  end
end
