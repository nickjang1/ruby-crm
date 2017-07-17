class AddRowOrderToMaintenanceChecklistItems < ActiveRecord::Migration
  def change
    add_column :maintenance_checklist_items, :row_order, :integer
  end
end
