class AddPropertyIdToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :property_id, :integer
  end
end
