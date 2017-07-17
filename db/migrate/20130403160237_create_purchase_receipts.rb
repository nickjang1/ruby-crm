class CreatePurchaseReceipts < ActiveRecord::Migration
  def change
    create_table :purchase_receipts do |t|
      t.references :user
      t.references :purchase_order

      t.timestamps
    end
    add_index :purchase_receipts, :user_id
  end
end
