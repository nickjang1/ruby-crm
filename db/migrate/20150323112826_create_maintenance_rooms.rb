class CreateMaintenanceRooms < ActiveRecord::Migration
  def change
    create_table :maintenance_rooms do |t|
      t.string :number
      t.integer :property_id
      t.integer :floor
    end
  end
end
