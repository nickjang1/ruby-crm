class CreateVendors < ActiveRecord::Migration
  def change
    create_table :vendors do |t|
      t.string :name
      t.string :street_address
      t.string :zip_code
      t.string :city
      t.string :email
      t.string :phone
      t.string :fax
      t.timestamps
    end
  end
end
