class AddSkuToVendorItem < ActiveRecord::Migration
  def change
    add_column :vendor_items, :sku, :string
  end
end
