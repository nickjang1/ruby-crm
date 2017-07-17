class CreateInspectionDetails < ActiveRecord::Migration
  def change
    create_table :maintenance_inspection_details do |t|
      t.integer :work_order_id
      t.integer :checklist_item_maintenance_id

      t.timestamps
    end
  end
end
