class CreateProcurementInterfaces < ActiveRecord::Migration
  def change
    create_table :procurement_interfaces do |t|
      t.string :interface_type
      t.text :data
      t.integer :vendor_id
    end
  end
end
