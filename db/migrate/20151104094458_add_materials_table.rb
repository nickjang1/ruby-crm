class AddMaterialsTable < ActiveRecord::Migration
  def change
    create_table :maintenance_materials do |t|
      t.integer :work_order_id
      t.integer :item_id
      t.decimal :quantity
      t.decimal :price

      t.timestamps
    end
  end
end
