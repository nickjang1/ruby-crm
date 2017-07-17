class AddFieldsToEquipment < ActiveRecord::Migration
  def change
    add_column :maintenance_equipment, :warranty, :integer
    add_column :maintenance_equipment, :lifespan, :integer
    add_column :maintenance_equipment, :removed, :boolean, default: false
  end
end
