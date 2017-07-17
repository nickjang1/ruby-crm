class CreateItemReceipts < ActiveRecord::Migration
  def change
    create_table :item_receipts do |t|
      t.references :purchase_receipt
      t.references :item_order
      t.references :item
      t.decimal :quantity
      t.decimal :price

      t.timestamps
    end
    add_index :item_receipts, :purchase_receipt_id
    add_index :item_receipts, :item_id
  end
end
