class AddStatusToPurchaseRequest < ActiveRecord::Migration
  def change
    add_column :purchase_requests, :state, :string
  end
end
