class AddIsDeletedToMaintenanceChecklistItems < ActiveRecord::Migration
  def change
    add_column :maintenance_checklist_items, :is_deleted, :boolean,:default=>false
  end
end
