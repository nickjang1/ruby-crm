class RenameColumnsInMaintenanceAttachments < ActiveRecord::Migration
  def change
    rename_column :maintenance_attachments, :equipmentable_id, :attachmentable_id
    rename_column :maintenance_attachments, :equipmentable_type, :attachmentable_type
  end
end
