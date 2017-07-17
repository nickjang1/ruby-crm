class AddRejectionReasonToPurchaseRequests < ActiveRecord::Migration
  def change
    add_column :purchase_requests, :rejection_reason, :text
  end
end
