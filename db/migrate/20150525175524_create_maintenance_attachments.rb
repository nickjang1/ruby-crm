class CreateMaintenanceAttachments < ActiveRecord::Migration
  def change
    create_table :maintenance_attachments do |t|
      t.string :file
      t.string :equipmentable_type
      t.integer :equipmentable_id

      t.timestamps
    end
  end
end
