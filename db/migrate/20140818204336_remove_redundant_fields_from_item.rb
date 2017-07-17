class RemoveRedundantFieldsFromItem < ActiveRecord::Migration
  def change
    remove_column :items, :purchase_cost_unit_id
    remove_column :items, :purchase_unit_id
  end
end
