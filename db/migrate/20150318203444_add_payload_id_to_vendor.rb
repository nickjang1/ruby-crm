class AddPayloadIdToVendor < ActiveRecord::Migration
  def change
    add_column :vendors, :payload_id, :string, default: nil
  end
end
