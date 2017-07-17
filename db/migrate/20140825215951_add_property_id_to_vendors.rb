class AddPropertyIdToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :property_id, :integer
  end
end
