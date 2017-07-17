class CreateItemRequests < ActiveRecord::Migration
  def change
    create_table :item_requests do |t|
      t.references :purchase_request
      t.references :item
      t.decimal :quantity
      t.decimal :count
      t.decimal :part_count

      t.timestamps
    end
    add_index :item_requests, :purchase_request_id
    add_index :item_requests, :item_id
  end
end
