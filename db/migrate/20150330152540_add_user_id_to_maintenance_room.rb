class AddUserIdToMaintenanceRoom < ActiveRecord::Migration
  def change
    add_reference :maintenance_rooms, :user, index: true
    rename_column :maintenance_rooms, :number, :room_number
    add_column :maintenance_rooms, :created_at, :datetime, default: nil
    add_column :maintenance_rooms, :updated_at, :datetime, default: nil
  end
end
