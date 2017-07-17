class CreateMaintenanceEquipment < ActiveRecord::Migration
  def change
    create_table :maintenance_equipment do |t|
      t.string :make
      t.string :name
      t.string :location
      t.date :buy_date
      t.date :replacement_date
      t.integer :property_id
      t.integer :equipment_type_id
      t.text :instruction

      t.timestamps
    end
  end
end
