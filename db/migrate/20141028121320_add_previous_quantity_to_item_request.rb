class AddPreviousQuantityToItemRequest < ActiveRecord::Migration
  def change
    add_column :item_requests, :prev_quantity, :decimal
  end
end
