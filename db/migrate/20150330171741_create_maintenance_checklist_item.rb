class CreateMaintenanceChecklistItem < ActiveRecord::Migration
  def change
    create_table :maintenance_checklist_items do |t|
      t.references :property, index: true
      t.references :user, index: true

      t.string :name
      t.string :maintenance_type
      t.integer :area_id, default: nil

      t.timestamps
    end
  end
end
