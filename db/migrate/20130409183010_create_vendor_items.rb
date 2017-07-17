class CreateVendorItems < ActiveRecord::Migration
  def change
    create_table :vendor_items do |t|
      t.boolean :preferred
      t.decimal :price
      t.decimal :items_per_box
      t.references :vendor
      t.references :item
      t.references :box_unit

      t.timestamps
    end
    add_index :vendor_items, :box_unit_id
  end
end
