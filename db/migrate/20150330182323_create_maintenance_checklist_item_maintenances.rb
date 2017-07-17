class CreateMaintenanceChecklistItemMaintenances < ActiveRecord::Migration
  def change
    create_table :maintenance_checklist_item_maintenances do |t|
      t.references :maintenance_record
      t.references :maintenance_checklist_item
      t.string :status, default: nil
      t.text :comment

      t.timestamps
    end
  end
end
