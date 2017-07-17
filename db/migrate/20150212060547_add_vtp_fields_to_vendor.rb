class AddVtpFieldsToVendor < ActiveRecord::Migration
  def change
    add_column :vendors, :division, :string
    add_column :vendors, :customer_number, :string
    add_column :vendors, :department_number, :string
    add_column :vendors, :customer_group, :string
  end
end
