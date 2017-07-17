class AddStateToPurchaseOrders < ActiveRecord::Migration
  def change
    add_column :purchase_orders, :state, :string
  end
end
