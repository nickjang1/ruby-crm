class ChangeUnits < ActiveRecord::Migration
  def change
    remove_column :items, :unit_id, :integer

    # Define Units
    add_reference :items, :unit, index: true
    add_reference :items, :subpack, index: true
    add_reference :items, :pack, index: true

    # Unit conversion
    add_column :items, :unit_subpack, :float
    add_column :items, :subpack_pack, :float

    # Use Units
    add_reference :items, :inventory_unit, index: true
    add_reference :items, :price_unit, index: true
    add_reference :items, :purchase_unit, index: true

    add_column :items, :property_id, :integer

    create_table :conversions do |t|
      t.references :unit
      t.float :factor
      t.references :other_unit

      t.timestamps
    end
  end
end
