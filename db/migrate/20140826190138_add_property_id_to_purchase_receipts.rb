class AddPropertyIdToPurchaseReceipts < ActiveRecord::Migration
  def change
    add_column :purchase_receipts, :property_id, :integer
  end
end
