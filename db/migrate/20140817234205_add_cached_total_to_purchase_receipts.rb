class AddCachedTotalToPurchaseReceipts < ActiveRecord::Migration
  def change
    add_column :purchase_receipts, :cached_total, :decimal
  end
end
