class AddFieldsToVendorAndProperty < ActiveRecord::Migration
  def change
    add_column :properties, :contact_name, :string
    add_column :properties, :street_address, :string
    add_column :properties, :zip_code, :string
    add_column :properties, :city, :string
    add_column :properties, :email, :string
    add_column :properties, :phone, :string
    add_column :properties, :fax, :string

    add_column :vendors, :contact_name, :string
    add_column :vendors, :shipping_method, :string
    add_column :vendors, :shipping_terms, :string
  end
end
