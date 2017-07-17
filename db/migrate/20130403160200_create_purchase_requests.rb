class CreatePurchaseRequests < ActiveRecord::Migration
  def change
    create_table :purchase_requests do |t|
      t.references :user

      t.timestamps
    end
    add_index :purchase_requests, :user_id
  end
end
