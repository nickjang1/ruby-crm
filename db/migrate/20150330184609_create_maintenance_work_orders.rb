class CreateMaintenanceWorkOrders < ActiveRecord::Migration
  def change
    create_table :maintenance_work_orders do |t|
      t.integer :maintainable_id
      t.string :maintainable_type
      t.integer :checklist_item_maintenance_id
      t.integer :opened_by_user_id, default: nil
      t.datetime :opened_at, default: nil
      t.string :status
      t.integer :closed_by_user_id, default: nil
      t.datetime :closed_at, default: nil
      t.text :closing_comment
      t.text :description

      t.timestamps
    end
  end
end
