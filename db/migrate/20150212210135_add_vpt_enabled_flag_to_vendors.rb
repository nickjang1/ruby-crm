class AddVptEnabledFlagToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :vpt_enabled, :boolean, default: false
  end
end
