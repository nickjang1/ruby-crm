class AddFieldsToItems < ActiveRecord::Migration
  def change
    add_column :items, :description, :text, limit: 500
    add_column :items, :is_asset, :boolean
    rename_column :items, :taxable, :is_taxable

    add_column :items, :purchase_cost, :decimal
    add_column :items, :purchase_cost_unit_id, :integer

    add_column :items, :pack_size, :decimal
    rename_column :items, :pack_id, :pack_unit_id

    rename_column :items, :subpack_id, :subpack_unit_id
    rename_column :items, :subpack_pack, :subpack_size

    add_column :items, :brand_id, :integer
  end
end
