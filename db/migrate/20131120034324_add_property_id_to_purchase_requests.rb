class AddPropertyIdToPurchaseRequests < ActiveRecord::Migration
  def change
    add_column :purchase_requests, :property_id, :integer
  end
end
