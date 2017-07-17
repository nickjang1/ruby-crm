class CreateItemOrders < ActiveRecord::Migration
  def change
    create_table :item_orders do |t|
      t.references :purchase_order
      t.references :item
      t.references :item_request
      t.decimal :quantity
      t.decimal :price

      t.timestamps
    end
    add_index :item_orders, :purchase_order_id
    add_index :item_orders, :item_id
    add_index :item_orders, :item_request_id
  end
end
