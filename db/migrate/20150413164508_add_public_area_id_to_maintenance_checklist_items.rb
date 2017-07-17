class AddPublicAreaIdToMaintenanceChecklistItems < ActiveRecord::Migration
  def change
    add_column :maintenance_checklist_items, :public_area_id, :integer
  end
end
