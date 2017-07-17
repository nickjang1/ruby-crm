class CreatePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :purchase_orders do |t|
      t.references :user
      t.references :purchase_request
      t.references :vendor
      t.datetime :sent_at
      t.datetime :closed_at

      t.timestamps
    end
    add_index :purchase_orders, :user_id
    add_index :purchase_orders, :purchase_request_id
    add_index :purchase_orders, :vendor_id
  end
end
