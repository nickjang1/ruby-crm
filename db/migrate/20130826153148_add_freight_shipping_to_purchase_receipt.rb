class AddFreightShippingToPurchaseReceipt < ActiveRecord::Migration
  def change
    add_column :purchase_receipts, :freight_shipping, :decimal
  end
end
