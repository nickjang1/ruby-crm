class CreateMaintenancePublicAreas < ActiveRecord::Migration
  def change
    create_table :maintenance_public_areas do |t|
      t.string :name
      t.integer :property_id
      t.integer :user_id
      t.boolean :is_deleted,default: false
      t.timestamps
    end
  end
end
