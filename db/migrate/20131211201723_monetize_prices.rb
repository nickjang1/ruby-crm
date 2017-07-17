class MonetizePrices < ActiveRecord::Migration
  def change
    remove_column :vendor_items, :price
    add_money :vendor_items, :price
  end
end
