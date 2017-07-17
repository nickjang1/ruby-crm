class CreateCorporateConnection < ActiveRecord::Migration
  def change
    create_table :corporate_connections do |t|
      t.integer :corporate_id
      t.integer :property_id
      t.string :email
      t.boolean :confirmed_by_corporate
      t.boolean :confirmed_by_property
    end
  end
end
