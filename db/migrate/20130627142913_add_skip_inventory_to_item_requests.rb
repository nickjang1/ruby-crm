class AddSkipInventoryToItemRequests < ActiveRecord::Migration
  def change
    add_column :item_requests, :skip_inventory, :boolean
  end
end
