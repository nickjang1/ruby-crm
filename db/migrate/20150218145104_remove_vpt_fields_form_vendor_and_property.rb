class RemoveVptFieldsFormVendorAndProperty < ActiveRecord::Migration
  def change
    remove_column :vendors, :division
    remove_column :vendors, :customer_number
    remove_column :vendors, :department_number
    remove_column :vendors, :customer_group
    remove_column :vendors, :vpt_enabled

    remove_column :properties, :vpt_partner_id
    remove_column :properties, :vpt_username
    remove_column :properties, :vpt_password

    remove_column :purchase_orders, :vpt_request_id
  end
end
